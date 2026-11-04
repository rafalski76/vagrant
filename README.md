# Vagrant

[![Lint](https://github.com/rafalski76/vagrant/actions/workflows/lint.yml/badge.svg)](https://github.com/rafalski76/vagrant/actions/workflows/lint.yml)

Przykłady tworzenia maszyn wirtualnych w [Vagrancie](https://www.vagrantup.com/) (provider VirtualBox).

## Wymagania

- [Vagrant](https://developer.hashicorp.com/vagrant/downloads)
- [VirtualBox](https://www.virtualbox.org/)
- (dla `2vms-loop`) plugin `vagrant plugin install vagrant-docker-compose`

Maszyny bazują na boxach `cloud-image/ubuntu-24.04` oraz `cloud-image/debian-13`
(oficjalne boxy z obsługą VirtualBoxa).

## Przykłady

| Katalog | Opis |
| --- | --- |
| `1vm-with-script/` | Jedna maszyna provisionowana skryptem powłoki (git, mc, nano, docker) |
| `2vms-loop/` | Dwie maszyny Debian tworzone w pętli, z Dockerem i docker-compose |
| `3-vms/` | Trzy maszyny Ubuntu w sieci prywatnej |
| `3nodes-k8s/` | Klaster Kubernetes (kubeadm + containerd + Calico): 1 master, 2 workery |
| `mysql-phpmyadmin/` | MySQL 8.4 i phpMyAdmin w kontenerach |
| `mysql-wordpress/` | MySQL 8.4 i WordPress w kontenerach |

## Użycie

```shell
cd 3nodes-k8s
vagrant up              # utworzenie i provisioning maszyn
vagrant ssh master      # połączenie do węzła master
kubectl get nodes       # na masterze
vagrant destroy -f      # usunięcie środowiska
```

Wersję Kubernetesa można zmienić zmienną `KUBERNETES_VERSION` (domyślnie `v1.37`) w `3nodes-k8s/scripts/common.sh`.

## Lint / CI

Workflow [`lint.yml`](.github/workflows/lint.yml) sprawdza skrypty (`shellcheck`), YAML (`yamllint`),
pliki `docker-compose.yml` (`docker compose config`) oraz składnię Vagrantfile (`ruby -c`).
