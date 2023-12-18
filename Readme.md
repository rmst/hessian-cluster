# Hessian-AI-Cluster Client Docker

This is a docker image to make it easy to connect to and use the Hessian-AI-Cluster.

```bash
docker run -it --rm --cap-add NET_ADMIN -e VPN_USER=<TU-ID> -e VPN_PASSWORD='<TU-Password>' -e DET_USER=<TU-ID> -e DET_PASSWORD='<DETERMINED-AI-PASSWORD>' -e SSH_PUB_KEY="$(cat ~/.ssh/id_*.pub | head -n 1)" -p 9541:9541 -v .:/wd simonramstedt/hessian-cluster      
```

Then the DeterminedAI webinterface should be at http://localhost:9541.

You'll also be dropped into a bash shell with `det` available and with the current directory mounted, i.e. the files in the directory in which you ran `docker run` are available inside the docker.


You can also make yourself an alias to make it easier to type (you can put that in your `.bashrc` or `.zshrc`)

```bash
alias hessian="docker run -it --rm --cap-add NET_ADMIN -e VPN_USER=<TU-ID> -e VPN_PASSWORD='<TU-Password>' -e DET_USER=<TU-ID> -e DET_PASSWORD='<DETERMINED-AI-PASSWORD>' -e SSH_PUB_KEY=\"$(cat ~/.ssh/id_*.pub | head -n 1)\" -p 9540-9550:9540-9550 -v .:/wd simonramstedt/hessian-cluster"
```

Then just can just run `hessian`. You can also run commands directly, e.g. to check whether you are logged-in properly do

```bash
hessian det user whoami
```

To get a remote shell (no GPUs) you can run (make sure to kill the shell job after you're done though)

```bash
hessian det-start -w $DETERMINED_WORKSPACE --template $DETERMINED_TEMPLATE --config resources.slots=0
```

To get a remote shell with two GPUs and our mount do

```bash
hessian det-start -w $DETERMINED_WORKSPACE --template $DETERMINED_TEMPLATE --config resources.slots=2
```


## Proper ssh access (e.g. for VSCode integration)

By default the docker tries to provide a ssh proxy to the most recently opened shell on port `9547`. This will also allow you to use it with the `VS Code Remote - SSH` extension. To connect you can just do. 

```bash
ssh -p 9547 $TU_ID@localhost
```

Or even better put the following in your `~/.ssh/config`

```
Host hessian
  User <TU-ID>
  HostName localhost
  Port 9547
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
```

Of course the docker need to be running for the ssh to keep working. By default it will connect to the last shell you opened but you can forward others by running the docker with `hessian det-ssh-forward $SHELL_ID`. 

## Advanced

Create templates that everyone can use

```bash
hessian det template create -w Ramstedt_Mila robin-0.1 config.yaml 
```


Check for other commands that are available in the docker

```bash
hessian cat /root/.bashrc
```


## Build
To build the docker image on your own machine just run

```bash
docker build -t hessian-cluster/latest .
```

To push the image to your own docker registry run
```bash
docker build -t $DOCKERHUB_USER/hessian-cluster/latest .
docker push $DOCKERHUB_USER/hessian-cluster/latest
```
