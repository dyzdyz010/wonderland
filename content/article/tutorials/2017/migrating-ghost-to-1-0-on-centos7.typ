#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "Migrating Ghost to 1.0 from 0.11.x on CentOS 7",
  desc: [Migrating Ghost to 1.0 from 0.11.x on CentOS 7],
  date: "2017-07-29",
  tags: (
    blog-tags.ghost,
    blog-tags.linux,
  ),
)

Ghost has released 1.0, with breaking changes so there's no smooth upgrading method but to take a fresh install. Here's my migration of this blog to Ghost 1.0.

There's already #link("https://docs.ghost.org/docs/migrating-to-ghost-1-0-0")[an official tutorial] to help you walk this through, but since it *only supports Ubuntu officially*, so I have to explore my own way on my `CentOS 7` server. It turns out that there's not much modifications compared to Ubuntu version, so I'm just writing this down as a record of my migration.

= Backup

The new version of Ghost uses almost-the-same data structure as the older version, so backup your content by following:
- Go to you `Admin` section, under `Labs`, click `Export` to make a backup json file of your posts, custom code injections, etc.
- Go to you site directory on your server to make a copy of `content` folder, your images lives there.
- Backup your `themes` folder as well, in case you put custom files in it, `highlightjs` for myself as an example.

= Install

In Ghost 1.0 or later it uses it's own CLI called `ghost` to manage sites, so install it by npm:

```bash
sudo npm i -g ghost-cli
```

Then create you site folder(For myself I created it under `/usr/share/nginx/`):

```bash
sudo mkdir /usr/share/nginx/ghost
cd /usr/share/nginx/ghost
```

Then start the install process:

```bash
ghost install local
```

Here I used `ghost install local` instead of `ghost install` to bypass mysql configuration.

When the installation was successfully done, it runs itself immediately. If you used `nginx/Apache` for your previous version of ghost, you may directly access this new site from your browser.

However, it configures your `site url` default to `http://localhost:2368`, you need to change it manually, among with other configurations like `mail`. Under your site root folder:

```bash
vim config.development.json
```

This makes your site runs under development mode, you can just copy it to `config.production.json` to make your site runs in production.

After you modifying your config file, run:

```bash
ghost restart
```

Your site will restart with new configurations and ready to roll!
