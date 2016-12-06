## Inclua build/install script ##

from setuptools import setup, find_packages
from codecs import open

with open ('README.rst', encoding = 'utf-8') as readme:
    long_description = readme.read ()

setup (
    name = 'inclua',
    version = '0.0.3',
    description = 'C/C++ to scripting languages wrapper generator, INitialy for binding C to LUA',
    long_description = long_description,

    url = 'https://github.com/gilzoide/inclua',
    author = 'gilzoide',
    author_email = 'gilzoide@gmail.com',

    license = 'GPLv3',
    classifiers = [
        'Development Status :: 3 - Alpha',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: GNU General Public License v3 or later (GPLv3+)',
        'Programming Language :: Python :: 2',
        'Programming Language :: Python :: 3',
    ],
    keywords = 'language bindings development',
    install_requires = ['libclang-py3', 'PyYAML'],

    packages = find_packages (),
    entry_points = {
        'console_scripts' : [
            'inclua = inclua:main',
        ]
    },
)
