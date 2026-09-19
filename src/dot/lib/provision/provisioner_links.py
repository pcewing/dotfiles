#!/usr/bin/env python

from dot.lib.common.links import Links
from dot.lib.common.log import Log
from dot.lib.provision.provisioner import IComponentProvisioner, ProvisionerArgs


class LinksProvisioner(IComponentProvisioner):
    def __init__(self, args: ProvisionerArgs) -> None:
        super().__init__(args)

    def provision(self) -> None:
        Log.info("creating dotfile symlinks")
        for link in Links.get():
            if self._args.dry_run:
                Log.info("would create symlink", {"src": link.src, "dst": link.dst})
                continue
            link.create()
