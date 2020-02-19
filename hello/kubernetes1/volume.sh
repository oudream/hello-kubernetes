
export NODE_IPS=(172.17.0.10 172.17.0.11 172.17.0.12 172.17.0.13)
export NODE_NAMES=(server1 node1 node2 node3)


### emptryDir
# emptryDir������˼����һ����Ŀ¼�������������ں������� Pod ����ȫһ�µġ�
#    emptyDir ���͵� Volume �� Pod ���䵽 Node ��ʱ�ᱻ������Kubernetes ���� Node ���Զ�����һ��Ŀ¼��
#    �������ָ�� Node �������϶�Ӧ��Ŀ¼�ļ������Ŀ¼�ĳ�ʼ����Ϊ�գ��� Pod �� Node ���Ƴ�
#    ��Pod ��ɾ������ Pod ����Ǩ�ƣ�ʱ��emptyDir �е����ݻᱻ����ɾ����
# emptyDir Volume ��Ҫ����ĳЩӦ�ó����������ñ������ʱĿ¼���ڶ������֮�乲�����ݵȡ�
#    ȱʡ����£�emptryDir ��ʹ���������̽��д洢�ġ���Ҳ����ʹ������������Ϊ�洢��
#    ���磺����洢���ڴ�ȡ����� emptyDir.medium �ֶε�ֵΪ Memory �Ϳ���ʹ���ڴ���д洢��
#    ʹ���ڴ���Ϊ�洢������������ٶȣ�����Ҫע��һ���������������ݾͻᱻ��գ�����Ҳ���ܵ������ڴ�����ơ�

apiVersion: v1
kind: Pod
metadata:
  name: test-pd
spec:
  containers:
  - image: gcr.io/google_containers/test-webserver
    name: test-container
    volumeMounts:
    - mountPath: /cache
      name: cache-volume
  volumes:
  - name: cache-volume
    emptyDir: {}



### hostPath
# hostPath ���͵� Volume �����û����� Node �������ϵ��ļ���Ŀ¼�� Pod �С������ Pod ���ò������� Volume��
# ��ȱ��Ƚ����ԣ����磺
#    ����ÿ���ڵ��ϵ��ļ�����ͬ��������ͬ���ã����磺�� podTemplate �����ģ��� Pod �ڲ�ͬ�ڵ��ϵ���Ϊ���ܻ�������ͬ��
#    �ڵײ������ϴ������ļ���Ŀ¼ֻ���� root д�롣����Ҫ����Ȩ�������� root ������н��̣�
#    ���޸������ϵ��ļ�Ȩ�޲ſ���д�� hostPath ��
# ��Ȼ�����ڼ������������͵� Volume ��Ҫ�������³����У�
#    �����е�������Ҫ���� Docker �ڲ���������ʹ�� /var/lib/docker ����Ϊ hostPath ��������Ӧ�ÿ���ֱ�ӷ���
#        Docker���ļ�ϵͳ��
#    ������������ cAdvisor��ʹ�� /dev/cgroups ����Ϊ hostPath��
#    �� DaemonSet ����ʹ�ã��������������ļ������磺��־�ɼ����� FLK �е� FluentD �Ͳ������ַ�ʽ������������
#        ������־Ŀ¼���ﵽ�ռ�������������־��Ŀ�ġ�

apiVersion: v1
kind: Pod
metadata:
  name: test-pd
spec:
  containers:
  - image: k8s.gcr.io/test-webserver
    name: test-container
    volumeMounts:
    - mountPath: /test-pd
      name: test-volume
  volumes:
  - name: test-volume
    hostPath:
      # directory location on host
      path: /data
      # this field is optional
      type: Directory


### nfs NFS
sudo apt install nfs-kernel-server
sudo mkdir -p /data/kubernetes/
sudo chmod 755 /data/kubernetes/
sudo vim /etc/exports
cat >> /etc/exports << EOF
/data/kubernetes  *(rw,sync,no_root_squash)
EOF

# ���� NFS �����
sudo systemctl restart nfs-kernel-server
# ��֤ NFS ������Ƿ���������
sudo rpcinfo -p|grep nfs

# �鿴����Ŀ¼����Ȩ��
cat /var/lib/nfs/etab

# ��װ NFS �ͻ���
sudo apt-get install nfs-common
# ��֤ RPC ����״̬
sudo systemctl status rpcbind.service
# ��� NFS ����˿��õĹ���Ŀ¼
sudo showmount -e ${NODE_IPS[0]}
# ���� NFS ����Ŀ¼������
sudo mkdir -p /data/kubernetes/
sudo mount -t nfs ${NODE_IPS[0]}:/data/kubernetes/ /data/kubernetes/


# �� NFS �ͻ����½�
sudo touch /data/kubernetes/test.txt
# �� NFS ����˲鿴
sudo ls -ls /data/kubernetes/

### ʵ�־�̬ PV :

cat >> pv1-nfs.yaml << EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name:  pv1-nfs
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    server: ${NODE_IPS[0]}
    path: /data/kubernetes
EOF

kubectl create -f pv1-nfs.yaml


cat >> pvc1-nfs.yaml << EOF
apiVersion: v1
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: pvc1-nfs
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

kubectl create -f pvc1-nfs.yaml


cat >> pvc2-nfs.yaml << EOF
apiVersion: v1
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: pvc2-nfs
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  selector:
    matchLabels:
      app: nfs
EOF

kubectl create -f pvc2-nfs.yaml


cat >> pv2-nfs.yaml << EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv2-nfs
  labels:
    app: nfs
spec:
  capacity:
    storage: 2Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    server: ${NODE_IPS[0]}
    path: /data/kubernetes
EOF

kubectl create -f pv2-nfs.yaml


### ʹ�� PVC ��Դ
# ���������Ѿ������ PV �� PVC �������������ǾͿ���ʹ����� PVC �ˡ�
#    ��������ʹ�� Nginx �ľ���������һ�� Deployment���������� /usr/share/nginx/html Ŀ¼ͨ�� Volume
#    ���ص���Ϊ pvc2-nfs �� PVC �ϣ���ͨ�� NodePort ���͵� Service ����¶����

cat >> nfs-pvc-deploy.yaml << EOF
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nfs-pvc
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: nfs-pvc
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
      volumes:
      - name: www
        persistentVolumeClaim:
          claimName: pvc2-nfs

---

apiVersion: v1
kind: Service
metadata:
  name: nfs-pvc
  labels:
    app: nfs-pvc
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: web
  selector:
    app: nfs-pvc
EOF

kubectl create -f nfs-pvc-deploy.yaml

kubectl get pods -o wide|grep nfs-pvc


curl -I http://${NODE_IPS[0]}:80

sudo sh -c "echo '<h1>Hello Kubernetes~</h1>' > /data/kubernetes/index.html"

curl -I http://${NODE_IPS[0]}:80

# ʹ�� subPath ��ͬһ�� PV ���и���
vim nfs-pvc-deploy.yaml

#...
#volumeMounts:
#- name: www
#  subPath: nginx-pvc-test
#  mountPath: /usr/share/nginx/html
#...
IFS_B=IFS;IFS=;s1="$(sed -n '/mountPath/p' nfs-pvc-deploy.yaml)"; \
s2=$(echo $s1 | sed -e 's/mountPath:\(.*\)$/subPath: nginx-pvc-test/'); \
sed -i.bak "/mountPath/ i \\${s2}" nfs-pvc-deploy.yaml; \
IFS=IFS_B;
