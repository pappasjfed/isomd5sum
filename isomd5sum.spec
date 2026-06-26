Name:           isomd5sum
Version:        1.2.5
Release:        1%{?dist}
Summary:        MD5 and SHA-256 checksum tools for ISO 9660 images
License:        GPL-2.0-only
URL:            https://github.com/rhinstaller/isomd5sum
Source0:        %{name}-%{version}.tar.bz2

BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  popt-devel
BuildRequires:  python3-devel
BuildRequires:  texinfo
BuildRequires:  xorriso

%description
isomd5sum provides tools to implant and verify MD5 or SHA-256 checksums
in ISO 9660 images.  The checksum is stored in the application data area
of the ISO 9660 Primary Volume Descriptor, allowing integrity verification
directly from the ISO file or from physical media without a separate
checksum file.

This package contains the command-line tools: implantisomd5, checkisomd5,
implantisosha, and checkisosha.

%package devel
Summary:        Development files for isomd5sum
Requires:       %{name} = %{version}-%{release}

%description devel
isomd5sum provides tools to implant and verify MD5 or SHA-256 checksums
in ISO 9660 images.

This package contains the static libraries and C header files for
developing applications that use the isomd5sum libraries.

%package doc
Summary:        Documentation for isomd5sum
BuildArch:      noarch
Requires:       info

%description doc
isomd5sum provides tools to implant and verify MD5 or SHA-256 checksums
in ISO 9660 images.

This package contains the GNU info manual and supplementary documentation
for isomd5sum.  It may be omitted when installing with --nodocs.

%package -n python3-%{name}
Summary:        Python 3 bindings for isomd5sum
Requires:       %{name} = %{version}-%{release}
%{?python_provide:%python_provide python3-%{name}}

%description -n python3-%{name}
isomd5sum provides tools to implant and verify MD5 or SHA-256 checksums
in ISO 9660 images.

This package contains the Python 3 bindings (pyisomd5sum) that expose
the isomd5sum libraries to Python scripts.

%prep
%autosetup

%build
%make_build
%make_build info

%install
%make_install
install -d -m 0755 %{buildroot}%{_infodir}
install -m 0644 isomd5sum.info %{buildroot}%{_infodir}/isomd5sum.info

%check
%make_build test-md5
%make_build test-sha

%post doc
/sbin/install-info %{_infodir}/isomd5sum.info %{_infodir}/dir || :

%preun doc
if [ $1 = 0 ]; then
    /sbin/install-info --delete %{_infodir}/isomd5sum.info %{_infodir}/dir || :
fi

%files
%license COPYING
%doc README
%{_bindir}/implantisomd5
%{_bindir}/implantisosha
%{_bindir}/checkisomd5
%{_bindir}/checkisosha
%{_mandir}/man1/implantisomd5.1*
%{_mandir}/man1/implantisosha.1*
%{_mandir}/man1/checkisomd5.1*
%{_mandir}/man1/checkisosha.1*

%files devel
%{_includedir}/libimplantisomd5.h
%{_includedir}/libimplantisosha.h
%{_includedir}/libcheckisomd5.h
%{_libdir}/libimplantisomd5.a
%{_libdir}/libimplantisosha.a
%{_libdir}/libcheckisomd5.a
%{_datadir}/pkgconfig/isomd5sum.pc

%files doc
%doc README COPYING
%{_infodir}/isomd5sum.info*

%files -n python3-%{name}
%{python3_sitearch}/pyisomd5sum.so

%changelog
* Thu Jan 01 2024 isomd5sum Maintainers <anaconda-devel-list@redhat.com> - 1.2.5-1
- Initial RPM packaging
