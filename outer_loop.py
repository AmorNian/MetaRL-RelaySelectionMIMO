import torch

def state_dict_to_cpu(state_dict):
    """Move all tensors in state_dict to CPU (avoid GPU-device mismatch)."""
    return {k: v.detach().cpu().clone() for k, v in state_dict.items()}

def add_state_dicts(dest, src, scale=1.0):
    """dest += scale * src (in-place). dest and src are state_dicts with tensors."""
    for k in dest.keys():
        dest[k] = dest[k] + src[k] * scale

def sub_state_dicts(a, b):
    """Return a - b as a new state_dict."""
    out = {}
    for k in a.keys():
        out[k] = a[k] - b[k]
    return out

def average_state_dicts(list_of_state_dicts):
    """Element-wise average of a list of state_dicts."""
    avg = {}
    n = len(list_of_state_dicts)
    if n == 0:
        return avg
    keys = list_of_state_dicts[0].keys()
    for k in keys:
        s = list_of_state_dicts[0][k].clone()
        for i in range(1, n):
            s += list_of_state_dicts[i][k]
        avg[k] = s / n
    return avg