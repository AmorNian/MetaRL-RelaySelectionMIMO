import gymnasium as gym
import numpy as np
import matlab.engine
from scipy.io import loadmat
import copy

class RelaySelectionEnv(gym.Env):

    def __init__(self, user_num, rs_num, is_train):
        self.user_num_max = 5
        self.rs_num = rs_num
        self.user_num = user_num 
        self.is_train = is_train
        """ self.eng = matlab.engine.start_matlab() """
        self.eng = matlab.engine.connect_matlab('MATLAB_16668')
        self.eng.addpath(self.eng.genpath("Matlab"))

        self.rand_seed = 1234
        ue_pos, rs_pos, matrix = self.eng.simulatorInit(self.rand_seed, nargout = 3)
        
        self.user_positions = np.array(ue_pos)  # N * 2
        self.rs_positions = np.array(rs_pos)  # M * 2    
        self.relay_user_matrix = np.array(matrix) # M * N
        
        self.selection_matrix = np.zeros((self.rs_num,self.user_num_max +1))

        """ self.observation_space = gym.spaces.Box(low=-np.inf, high=np.inf, shape=(self.user_num_max*2 + self.rs_num*2 + self.user_num_max * self.rs_num + self.rs_num,), dtype=np.float32) """
        self.observation_space = gym.spaces.Box(low=-np.inf, high=np.inf, shape=(self.user_num_max * self.rs_num + self.rs_num,), dtype=np.float32)
        self.action_space = gym.spaces.Discrete(self.user_num_max+1)

        self.alpha = 1

    def reset(self, seed = None, options = None):
        super().reset(seed=seed)

        self.selection_matrix = np.zeros(self.rs_num)
        self.user_mask_0 = np.concatenate([np.ones(self.user_num + 1), np.zeros(self.user_num_max - self.user_num)])
        self.current_rs = 0
        self.sum_reward = 0
        self.right_num = 0
        self.sys_cap = 0
        self.ue_done = np.where(self.relay_user_matrix[self.current_rs,:] == 0)[0]
        self.ue_done = self.ue_done + 1
        self.user_mask = self.user_mask_0.copy()
        self.user_mask[self.ue_done] = 0
        self.jain_index = 0
        return self._get_obs(), {}


    def _get_obs(self):
        """ obs = np.concatenate([self.user_positions.flatten(),self.rs_positions.flatten(),self.relay_user_matrix.flatten(),self.selection_matrix.flatten()]).astype(np.float32) """
        """print("obs shape:", obs.shape)
        print("obs min/max:", obs.min(), obs.max())
        print("observation_space:", self.observation_space) """
        obs = np.concatenate([self.relay_user_matrix.flatten(),self.selection_matrix.flatten()]).astype(np.float32)
        return obs
    
    def step(self,action):
        #print("mask:",self.user_mask)
        if self.is_train == False:
            print("#RS:",self.current_rs,"action:",action)
 
        #判断action合法性
        idx = np.where(self.relay_user_matrix[self.current_rs,:] == 1)[0]
        idx = idx + 1
        idx = np.concatenate(([0], idx))
        
        if np.isin(action,idx):
            if len(idx) == 1:
                reward = 0
            else:
                self.selection_matrix[self.current_rs] = action
                if sum(self.selection_matrix) != 0 and action != 0:
                    cap_vec = np.array(self.eng.getReward(self.selection_matrix))/1e10
                    new_cap = np.sum(cap_vec)
                    self.jain_index = self.jain_fairness(cap_vec)
                    reward = self.alpha * (new_cap - self.sys_cap) + (1 - self.alpha) * self.jain_index
                    self.sys_cap = new_cap
                elif sum(self.selection_matrix) != 0 and action == 0 :
                    reward = 0 + (1 - self.alpha) * self.jain_index
                else:
                    new_cap = 0
                    reward = 0
                
                self.right_num += 1
        else:
            raise ValueError("action error")
        
        #print("raward:",reward)


        #reward = self.eng.getReward(self.user_index,self.selection_matrix)
        
        done = self.current_rs == self.rs_num - 1
        truncated = False
        self.sum_reward += reward
        if done:
            print("cap:" , self.sys_cap)
            if self.is_train == False:
                cap_ke = self.get_KeCap()
                print("Ke Cap:", np.sum(cap_ke))
        else:
            self.current_rs += 1
            self.ue_done = np.where(self.relay_user_matrix[self.current_rs,:] == 0)[0]
            self.ue_done = self.ue_done + 1
            self.user_mask = self.user_mask_0.copy()
            self.user_mask[self.ue_done] = 0

        return self._get_obs(), reward, done, truncated, {}
    
    def close(self):
        self.eng,quit()

    def jain_fairness(self,x):
        if np.all(x == 0):
            return 0.0
        numerator = np.sum(x) ** 2
        denominator = len(x) * np.sum(x ** 2)
        return numerator / denominator
    
    def get_KeCap(self):
        return np.array(self.eng.getKeCap())


