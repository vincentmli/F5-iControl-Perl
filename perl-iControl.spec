Name:           perl-iControl
Version:        1.00100
Release:        1%{?dist}
Summary:        Perl module for iControl functionality. It provides methods that use iControl via SOAP::Lite to manage bigip
License:        CHECK(GPL+ or Artistic)
Group:          Development/Libraries
URL:            https://github.com/gpetras/F5-iControl-Perl
Source0:        %{name}-%{version}.tar.gz
Source1:        iControlTypeCast.pm.11.1.0
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(IO::Socket::SSL)
BuildRequires:  perl(Net::SSH::Expect)
BuildRequires:  perl(SOAP::Lite)
BuildRequires:  perl(Socket)
BuildRequires:  perl(Sys::Syslog)
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
Provides:	perl(iControlTypeCast)

%description
iControl provides an Object Oriented Perl interface to implement some of
the interfaces provided by iControl.

%prep
%setup -q -n iControl-%{version}

%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT

make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT

find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} \;
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

install -m 0644 %SOURCE1 $RPM_BUILD_ROOT/%{perl_vendorlib}/iControlTypeCast.pm

%{_fixperms} $RPM_BUILD_ROOT/*

%check
make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc README.md
%{perl_vendorlib}/*
%{_mandir}/man3/*

%changelog
* Wed Jul 17 2013 Greg Petras <greg.petras@nwea.org> 1.00100-1
- Specfile autogenerated by cpanspec 1.78. Modified URLs to reflect correct source.
