#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

pipVersion="$(curl -sSL 'https://pypi.python.org/pypi/pip/json' | awk -F '"' '$2 == "version" { print $4 }')"

for version in "${versions[@]}"; do
	case "$version" in
		3) pypy="pypy3.3" ;;
		2) pypy='pypy2' ;;
		*) echo >&2 "error: unknown pypy variant $version"; exit 1 ;;
	esac
	# <td class="name"><a class="execute" href="/pypy/pypy/downloads/pypy-2.4.0-linux64.tar.bz2">pypy-2.4.0-linux64.tar.bz2</a></td>
	# <td class="name"><a class="execute" href="/pypy/pypy/downloads/pypy3-2.4.0-linux64.tar.bz2">pypy3-2.4.0-linux64.tar.bz2</a></td>
	fullVersion="$(curl -sSL 'https://bitbucket.org/pypy/pypy/downloads' | grep -E "$pypy"'-v([0-9.]+(-alpha[0-9]*)?)-linux64.tar.bz2' | sed -r 's/^.*'"$pypy"'-v([0-9.]+(-alpha[0-9]*)?)-linux64.tar.bz2.*$/\1/' | sort -V | tail -1)"

	(
		set -x
		sed -ri '
			s/^(ENV PYPY_VERSION) .*/\1 '"$fullVersion"'/;
			s/^(ENV PYTHON_PIP_VERSION) .*/\1 '"$pipVersion"'/;
		' "$version"{,/slim}/Dockerfile
		sed -ri 's/^(FROM pypy):.*/\1:'"$version"'/' "$version/onbuild/Dockerfile"
	)
done
