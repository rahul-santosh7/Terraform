[WindowsServer]
%{ for ip in ips ~}
${ip}
%{ endfor ~}