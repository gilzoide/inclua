from codecs import open
from setuptools import setup, find_packages

with open('README.rst', encoding='utf-8') as readme:
    long_description = readme.read()

setup(
    name='inclua',
    description='C to scripting languages wrapper generator, INitialy for binding C to LUA',
    long_description=long_description,

    url='https://github.com/gilzoide/inclua',
    author='gilzoide',
    author_email='gilzoide@gmail.com',

    license='GPLv3',
    classifiers=[
        'Development Status :: 3 - Alpha',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: GNU General Public License v3 or later (GPLv3+)',
        'Programming Language :: Python :: 2',
        'Programming Language :: Python :: 3',
    ],
    keywords='language bindings development',
    install_requires=['c_api_extract >= 0.4', 'docopt', 'pyyaml'],

    packages=find_packages(),
    entry_points={
        'console_scripts': [
            'inclua = inclua.__main__:main',
        ]
    },
)
