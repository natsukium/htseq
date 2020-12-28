#!/bin/bash
#
# Build manylinux wheels for HTSeq. Based on the example at
# <https://github.com/pypa/python-manylinux-demo>
#
# It is best to run this in a fresh clone of the repository!
#
# Run this within the repository root:
#   docker run --rm -v $(pwd):/io quay.io/pypa/manylinux2010_x86_64 /io/buildwheels.sh
#
# The wheels will be put into the wheelhouse/ subdirectory.
#
# For interactive tests:
#   docker run -it -v $(pwd):/io quay.io/pypa/manylinux2010_x86_64 /bin/bash

set -xeuo pipefail

# For convenience, if this script is called from outside of a docker container,
# it starts a container and runs itself inside of it.
if ! grep -q docker /proc/1/cgroup; then
  # We are not inside a container
  exec docker run --rm -v $(pwd):/io quay.io/pypa/manylinux2010_x86_64 /io/$0
fi


# Build wheels
PYBINS="/opt/python/*/bin"
for PYBIN in ${PYBINS}; do
    echo "PYBIN = ${PYBIN}"

    echo "Install requirements..."
    ${PYBIN}/pip install setuptools wheel Cython matplotlib
    ${PYBIN}/pip install -r /io/requirements.txt

    echo "Build wheels..."
    ${PYBIN}/pip wheel /io/ -w wheelhouse/
done

# Repair HTSeq wheels, copy libraries
for whl in wheelhouse/*.whl; do
    if [[ $whl == wheelhouse/HTSeq* ]]; then
      echo "Repairing wheel: $whl"
      auditwheel repair -L . $whl -w /io/wheelhouse/
    else
      echo "Copying wheel: $whl"
      cp $whl /io/wheelhouse/
    fi
done

# Created files are owned by root, so fix permissions.
chown -R --reference=/io/setup.py /io/wheelhouse/

echo "Build source dist..."
cd /io
${PYBIN}/python setup.py sdist --dist-dir /io/wheelhouse/
echo "Done building"
