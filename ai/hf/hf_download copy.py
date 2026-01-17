import argparse
import os
import sys
import time
import random

# 检查并安装依赖
try:
    import huggingface_hub
except ImportError:
    print("Install huggingface_hub.")
    os.system("pip install -U huggingface_hub")

parser = argparse.ArgumentParser(description="HuggingFace Download Script with Rate Limiting.")
parser.add_argument("--model", "-M", default=None, type=str, help="模型名称")
parser.add_argument("--token", "-T", default=None, type=str, help="Hugging Face访问令牌")
parser.add_argument("--include", default=None, type=str, help="指定下载的文件")
parser.add_argument("--exclude", default=None, type=str, help="排除下载的文件")
parser.add_argument("--dataset", "-D", default=None, type=str, help="数据集名称")
parser.add_argument("--save_dir", "-S", default=None, type=str, help="保存路径")
parser.add_argument("--use_hf_transfer", default=True, type=eval, help="使用hf-transfer下载")
parser.add_argument("--use_mirror", default=True, type=eval, help="使用镜像站点")
parser.add_argument("--min_delay", default=5, type=int, help="下载最小延迟（秒）")
parser.add_argument("--max_delay", default=15, type=int, help="下载最大延迟（秒）")

args = parser.parse_args()

# ---------------------- 防限速核心配置 ----------------------
# 1. 单线程下载（降低并行请求）
if args.use_hf_transfer:
    os.environ["HF_HUB_NUM_THREADS"] = "1"  # 强制单线程
    os.environ["HF_HUB_DISABLE_TQDM"] = "1"  # 关闭进度条（减少状态请求）

# 2. 使用镜像站点（降低网络延迟）
if args.use_mirror:
    os.environ["HF_ENDPOINT"] = "https://hf-mirror.com"  # 国内镜像
    print(f"[镜像配置] 使用镜像站点: {os.getenv('HF_ENDPOINT')}")

# 3. 自动创建保存目录（避免权限问题）
if args.save_dir and not os.path.exists(args.save_dir):
    os.makedirs(args.save_dir, exist_ok=True)

# 4. 处理Token（支持环境变量传入）
args.token = args.token or os.getenv("HF_TOKEN")
token_option = f"--token {args.token}" if args.token else ""

# 5. 格式化文件包含/排除参数（避免命令解析错误）
include_option = f'--include "{args.include}"' if args.include else ""
exclude_option = f'--exclude "{args.exclude}"' if args.exclude else ""

# ---------------------- 下载逻辑 ----------------------
def download_with_delay(shell_cmd, min_delay=5, max_delay=15):
    """带随机延迟的下载函数"""
    delay = random.uniform(min_delay, max_delay)
    print(f"[延迟下载] 等待 {delay:.1f} 秒后开始下载...")
    time.sleep(delay)
    os.system(shell_cmd)

if args.model:
    model_owner, model_name = args.model.split("/")
    save_path = os.path.join(args.save_dir, f"models--{model_owner}--{model_name}") if args.save_dir else ""
    save_dir_option = f"--local-dir {save_path}" if save_path else ""
    
    download_shell = (
        f"huggingface-cli download {token_option} {include_option} {exclude_option} "
        f"--local-dir-use-symlinks False --resume-download {args.model} {save_dir_option}"
    )
    download_with_delay(download_shell, args.min_delay, args.max_delay)

elif args.dataset:
    dataset_owner, dataset_name = args.dataset.split("/")
    save_path = os.path.join(args.save_dir, f"datasets--{dataset_owner}--{dataset_name}") if args.save_dir else ""
    save_dir_option = f"--local-dir {save_path}" if save_path else ""
    
    download_shell = (
        f"huggingface-cli download {token_option} {include_option} {exclude_option} "
        f"--local-dir-use-symlinks False --resume-download --repo-type dataset {args.dataset} {save_dir_option}"
    )
    download_with_delay(download_shell, args.min_delay, args.max_delay)

else:
    print("请指定 --model 或 --dataset 参数")
    sys.exit(1)

# python hf_download.py --dataset airvlab/Grasp-Anything --save_dir ./hf_hub --use_mirror True --min_delay 8 --max_delay 12

#
#export HF_TOKEN=hf_your_token_here
#python hf_download.py --model meta-llama/Llama-2-7b-hf --save_dir ./models --use_hf_transfer True --min_delay 5
#