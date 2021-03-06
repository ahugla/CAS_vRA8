import paramiko     # pip3 install paramiko
import time         # pas besoin de metttre en dependance car deja dans librairie par defaut

def handler(context, inputs):
  
  # Attend 60 sec que l'install du minion via cloud-init se termine
  time.sleep(60)  
  
  salt_master = inputs["customProperties"] ["salt_master"]  # ip du salt master
  username="root"
  salt_master_password = inputs["customProperties"] ["salt_master_password"]  # password de username sur le master
 
 # Creation de la commande
  minion_ID = inputs["resourceNames"][0] +"*"         # on rajoute l'etoile pour prendre en compte le hostname ou le FQDN
  cmd_to_execute="salt-key -y --accept=" +minion_ID

  #logs
  print("server salt master : " +salt_master)
  print("minion ID : " +minion_ID)
  print("command to execute : " +cmd_to_execute)

  # execution SSH
  client = paramiko.SSHClient()
  client.set_missing_host_key_policy(paramiko.MissingHostKeyPolicy())    # pas de check de clé
  client.connect(salt_master, username=username, password=salt_master_password)
  ssh_stdin, ssh_stdout, ssh_stderr = client.exec_command(cmd_to_execute)
  
  # affichage de la sortie de la commande
  for line in ssh_stdout:
    print('... ' + line.strip('\n'))
  
  client.close()


  outputs={"status":"Register minion terminé"}
  return outputs
  

