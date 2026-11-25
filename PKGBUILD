# Maintainer: niiithish <https://github.com/niiithish>
pkgname=gamebox-git
pkgver=r1
pkgrel=1
pkgdesc="Try Windows games on Linux in a jailed, offline bubblewrap + Wine sandbox"
arch=('any')
url="https://github.com/niiithish/gamebox"
license=('MIT')
depends=('bash' 'bubblewrap' 'wine' 'winetricks' 'util-linux')
optdepends=('libnotify: error notifications when launched from a shortcut')
makedepends=('git')
provides=('gamebox')
conflicts=('gamebox')
source=("git+$url.git")
sha256sums=('SKIP')

pkgver() {
  cd gamebox
  printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

package() {
  cd gamebox
  install -Dm755 gamebox "$pkgdir/usr/bin/gamebox"
  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
  install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
}
