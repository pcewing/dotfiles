#!/usr/bin/env python

from ..common.provisioner import Provisioners

from .provisioner import UbuntuJammyProvisioner

Provisioners.register("jammy", UbuntuJammyProvisioner)
