import os
import boto3
import json
import xml.etree.ElementTree as ET
import shutil


def main():
    env_name = get_environment()
    ecr_repo_name = f"comments/{env_name}/code-images"
    print(f"::set-output name=ecr_repo_name::{ecr_repo_name}")


def get_environment():
    env_name = os.environ.get("GITHUB_BASE_REF", "")
    env_name_parts = env_name.split("/")
    env_name = env_name_parts[-1]
    if env_name == "main":
        env_name = "prod"

    return env_name


########## START ##########
if __name__ == "__main__":
    main()
