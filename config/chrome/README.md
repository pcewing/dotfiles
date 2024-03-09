## Google Chrome Vimium Setup Steps

Unfortunately there's no way to my knowledge to set Chrome configuration up as
a "dotfile" so these things just have to be done manually.

### Install Extensions

- [Vimium](https://chromewebstore.google.com/detail/vimium/dbepggeogbaibhgnhhndojpepiihcmeb)
- [New Tab Redirect](https://chromewebstore.google.com/detail/new-tab-redirect/icpgjfneehieebagbmdbhnlpiopdcmna)

### Allow Local File Access

- For both Vimium and New Tab Redirect
    - Click the extensions icon in Chrome toolbar
    - Click the three dot hamburger (More options) menu button next to the extension
    - Select the `Manage extension` menu item
    - Ensure the `Allow access to file URLs` option is enabled

### New Tab Redirect

When opening a new tab via `<ctrl-t>`, Chrome will open to a page Vimium
doesn't work in. This is annoying and there's currently no built-in setting to
change that landing page, hence why we install the `New Tab Redirect`
extension.

In the options for the `New Tab Redirect` extension, set the `Redirect URL` to:

- Linux
    - `file:///home/<USERNAME>/dot/config/chrome/home.html`
- Windows
    - `file:///C:/Users/<USERNAME>/dot/config/chrome/home.html`

As an alternative to `New Tab Redirect`, we could make our own extension as
described here:

https://superuser.com/questions/907234/change-chrome-new-tab-page-to-local-file

Doesn't sound all that complicated but haven't done it yet.

### Vimium Options

- Click the extensions icon in Chrome toolbar
- Click the three dot hamburger (More options) menu button next to Vimium
- Select the `Options` menu item

#### Excluded URLs and keys

**TODO:** Copy paste these from my existing browser settings here.

#### Custom Key Mappings

Copy paste these into the `Custom Key Mappings` form field:

```
# Swap o/O and b/B so the new tab variants don't require shift
# TODO: Is it necessary to unmap these first?
unmap o
unmap O
unmap b
unmap B
map o Vomnibar.activateInNewTab
map O Vomnibar.activate
map b Vomnibar.activateBookmarksInNewTab
map B Vomnibar.activateBookmarks
```

#### New Tab URL

Set this to the same URL as what was used in the `New Tab Redirect` section
above.
