#!/bin/bash
hzn unregister -f -r
sudo apt remove -y bluehorizon horizon horizon-cli
sudo apt purge -y bluehorizon horizon horizon-cli
