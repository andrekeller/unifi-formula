unifi_tls_crt:
  file.managed:
    - name: /var/cache/salt/unifi.crt
    - mode: 0400
    - source: {{ salt.pillar.get('unifi_tls_cert') }}
unifi_tls_key:
  file.managed:
    - name: /var/cache/salt/unifi.key
    - mode: 0400
    - source: {{ salt.pillar.get('unifi_tls_key') }}
unifi_tls_chain:
  file.managed:
    - name: /var/cache/salt/unifi.chain
    - mode: 0400
    - source: {{ salt.pillar.get('unifi_tls_chain') }}

unifi_tls_pkcs12:
  cmd.run:
    - name: |
        openssl pkcs12 -export -in {{ salt.pillar.get('unifi_tls_cert') }} \
                               -inkey {{ salt.pillar.get('unifi_tls_key') }} \
                               -CAfile {{ salt.pillar.get('unifi_tls_chain') }} \
                               -out /var/cache/salt/unifi.p12 \
                               -name unifi \
                               -caname root \
                               -password pass:aircontrolenterprise
    - onchanges:
      - file: unifi_tls_chain
      - file: unifi_tls_crt
      - file: unifi_tls_key

unifi_keystore:
  cmd.run:
    - name: |
        keytool -importkeystore \
                -deststorepass aircontrolenterprise \
                -destkeypass aircontrolenterprise \
                -destkeystore /var/lib/unifi/data/keystore \
                -srckeystore /var/cache/salt/unifi.p12 \
                -srcstoretype PKCS12 \
                -srcstorepass aircontrolenterprise \
                -noprompt \
                -alias unifi &&
        chown unifi:unifi /var/lib/unifi/data/keystore
    - require:
      - pkg: unifi
    - onchanges:
      - cmd: unifi_tls_pkcs12
    - watch_in:
      - service: unifi

unifi:
  pkg.installed:
    - pkgs:
      - unifi
    - require:
      - sls: pacman
  service.running:
    - name: unifi
    - enable: True
