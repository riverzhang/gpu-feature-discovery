# How to

To use this setup, you need to:

- Place this directory at the root of your repo, with `aws-kube-ci` as name
- In your `.gitlab-ci.yaml`, define the stages `aws_kube_setup` and `aws_kube_clean`
- In your `.gitlab-ci.yaml`, import the `aws-kube-ci.yaml` file
- Write a terraform variable file with those variables:
	- `instance_type`: The AWS instance type
	- `instance_name`: The name of the instance, like `ci-gpu-feature-discovery`
- In your .gitlab-ci.yaml, set the `TF_VAR_FILE` to the path of the previous file
- Write your ci task

You should write your tasks in a stage which is between `aws_kube_setup` and `aws_kube_clean`.

The `aws_kube_setup` job will expose different files as artifacts:
- The private key to connect to the VM: `aws-kube-ci/key`
- The associated public key: `aws-kube-ci/key.pub`
- A file to source to get the `user@hostname` in the env: `aws-kube-ci/hostname`. The env
	variable is `instance_hostname`.
