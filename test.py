import matlab.engine
import torch
print("hello world")
print(torch.__version__)
print(torch.cuda.is_available())
print(torch.cuda.get_device_name(0))