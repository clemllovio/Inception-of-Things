# Inception-of-Things

## Part 1
```
vagrant up
vagrant ssh <machine_name>
```

**Server machine**
```
ip a show eth1
hostname
sudo systemctl status k3s
sudo kubectl get nodes -o wide -> Display the list of nodes in the K8s cluster
```

**Server Worker machine**
```
ip a show eth1
hostname
sudo systemctl status k3s-agent 
```
## Part 2
```
vagrant up
vagrant ssh <machine_name>
ip a show eth1
hostname
sudo systemctl status k3s
sudo kubectl get nodes -o wide
sudo kubectl get ingress
sudo kubectl get pods
sudo kubectl get svc
```
## Part 3
```
k3d cluster list
kubectl get ns
kubectl get pods -n argocd
kubectl get pods -n dev
kubectl get applications -n argocd
kubectl get nodes -o wide
kubectl get services -A
```