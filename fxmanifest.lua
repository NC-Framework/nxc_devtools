fx_version 'cerulean'
game 'gta5'

author 'The Nexus Core Framework team'
description 'Development diagnostics for Nexus Core. Gated by development mode and capability.'
version '0.1.0'

shared_scripts {
    'shared/*.lua',
}

client_scripts {
    'client/*.lua',
}

server_scripts {
    'server/*.lua',
}

dependencies {
    'nxc_lib',
    'nxc_core',
}
