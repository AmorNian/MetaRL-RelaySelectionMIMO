import numpy as np
import torch

import gymnasium as gym
from stable_baselines3.common.vec_env import DummyVecEnv
from sb3_contrib import MaskablePPO
from sb3_contrib.common.wrappers import ActionMasker
from sb3_contrib.common.maskable.policies import MaskableActorCriticPolicy
from Environment import RelaySelectionEnv
import outer_loop as ol
import matlab.engine


eng = matlab.engine.connect_matlab('meta')
eng.addpath(eng.genpath("Matlab"))

def mask_fn(env: gym.Env) -> np.ndarray:
    return env.user_mask

def make_env(rand_seed, is_train = True, eng = eng):
    def _init():
        env = RelaySelectionEnv(rand_seed, is_train=is_train, eng=eng)
        env = ActionMasker(env, mask_fn)
        return env
    return _init

def reptile_meta_train(
    meta_iterations: int = 1000,
    meta_batch_size: int = 8,
    inner_timesteps: int = 1000,
    meta_lr: float = 0.1,
    inner_lr: float = 5e-5,
):
    rand_seed_base = 42
    dummy = DummyVecEnv([make_env(0)])
    meta_model = MaskablePPO(
        MaskableActorCriticPolicy,
        dummy,
        learning_rate=inner_lr,
        device='cuda',
        verbose=0
    )

    # 2. 主 meta-loop
    for outer_iter in range(meta_iterations):
        
        meta_params = ol.state_dict_to_cpu(meta_model.policy.state_dict())

        # 收集每个任务更新后的 θ_i
        task_params_list = []

        for inner_iter in range(meta_batch_size):
            rand_seed = rand_seed_base + outer_iter * meta_batch_size + inner_iter
            env = DummyVecEnv([make_env(rand_seed)])
            inner_model = MaskablePPO(
                MaskableActorCriticPolicy,
                env,
                learning_rate=inner_lr,
                device='cuda',
                verbose=0
            )
            inner_model.policy.load_state_dict(meta_params, strict=True)
            inner_model.learn(total_timesteps=inner_timesteps)

            # 保存更新后的参数 θ_i
            updated_params = ol.state_dict_to_cpu(inner_model.policy.state_dict())
            task_params_list.append(updated_params)
            del inner_model
            torch.cuda.empty_cache()


        # --- Reptile Meta-update ---
        avg_params = ol.average_state_dicts(task_params_list)
        diff = ol.sub_state_dicts(avg_params, meta_params)  # θ_avg − θ
        ol.add_state_dicts(meta_params, diff, scale=meta_lr)  # θ ← θ + β*(θ_avg−θ)

        # 将 meta 参数加载回模型
        meta_model.policy.load_state_dict(meta_params, strict=True)

        print(f"[Meta Iter {outer_iter}] Meta-update finished.")

    return meta_model

if __name__ == "__main__":
    meta_model = reptile_meta_train()
    meta_model.save("meta_model")
    print("Meta training complete. Meta model saved.")