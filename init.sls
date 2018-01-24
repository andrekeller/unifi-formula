unifi:
  pkg.installed:
    - pkgs:
      - unifi
    - require:
      - sls: pacman
  service.running:
    - name: unifi
    - enable: True
