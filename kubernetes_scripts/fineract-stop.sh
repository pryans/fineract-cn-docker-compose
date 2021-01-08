#!/bin/bash -x

kubectl delete -f notifications.yml
kubectl delete -f group.yml
kubectl delete -f payroll.yml
kubectl delete -f cheques.yml
kubectl delete -f reporting.yml
kubectl delete -f teller.yml
kubectl delete -f deposit.yml
kubectl delete -f portfolio.yml
kubectl delete -f accounting.yml
kubectl delete -f customer.yml
kubectl delete -f office.yml
kubectl delete -f rhythm.yml
kubectl delete -f identity.yml
kubectl delete -f provisioner.yml
kubectl delete configmaps external-tools-config
kubectl delete configmaps fineract-service-config
kubectl delete configmaps secret-config
kubectl delete configmaps provisioner-datasource-config
kubectl delete -f postgres.yml
kubectl delete -f cassandra.yml
kubectl delete -f eureka.yml
kubectl delete -f activemq.yml
kubectl delete -f fims-web-app.yml

rm ../bash_scripts/cluster_addressess.txt
