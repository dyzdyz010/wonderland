#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "Install RHEL 8 With SAS 2008 Raid Controllers",
  desc: [Install RHEL 8 With SAS 2008 Raid Controllers],
  date: "2021-01-03",
  tags: (
    blog-tags.linux,
  ),
)

Reference: #link("https://gainanov.pro/eng-blog/linux/rhel8-install-to-dell-raid/")[RHEL8. Install to DELL server with RAID (SAS2008) by Ruslan Gainanov]

In RHEL 8 many hardware drivers are #link("https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/considerations_in_adopting_rhel_8/hardware-enablement_considerations-in-adopting-rhel-8#removed-adapters_hardware-enablement")[removed], including the `SAS 2008 RAID bus Controller` I'm using. I tried to install RHEL 8 on my machine, and only got an *empty* list of available disks in `Installation Destination` section.

To install the OS we need to acquire this hardware's driver, luckily we got DUD(Driver Update Disk) from #link("https://elrepo.org/linux/dud/el8/x86_64/")[ELRepo], thus we can get the missing drive from there. Next I'll show you how I managed to install RHEL 8 on my server with SAS 2008 RAID Controller.

= Figure out Device ID

First we gotta figure out what device ID of my hardware is. When get into the installer GUI, get a shell by `Ctrl + Alt + F2`, type in the command below:

```
lspci -nn
```

You may want to filter out with some keywords to make the output more clean and readable. Here's what I got:

#figure(image("/public/assets/img/2021/01/photo_2021-01-04_18-29-35.jpg"), caption: "lspci output")

So the device I'm looking for is:

```
05:00.0 RAID bus Controller [0104]: Broadcom / LSI MegaRAID SAS 2008 [Falcon] [1000:0073] (rev 03)
```

And the Device ID of this hardware is `1000:0073`.

= Get the driver

Now we need to go to the #link("http://elrepo.org/tiki/DeviceIDs")[Device ID Parings] page of ELRepo to get the driver name. In this case, mine is `megaraid_sas`.

Go to #link("https://elrepo.org/linux/dud/el8/x86_64/")[DUD List Page] and find the driver by name:

#figure(image("/public/assets/img/2021/01/202101041837.png"), caption: "DUD List Page")

I'm installing RHEL 8.3 so I'll use the last match: `dd-megaraid_sas-07.714.04.00-1.el8_3.elrepo.iso`.

Follow #link("https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/performing_an_advanced_rhel_installation/updating-drivers-during-installation_installing-rhel-as-an-experienced-user")[RedHat's documentation] for how to use this driver. In my case I just copied the `iso` file to another USB drive.

= Patch the driver

I'll just show what I did, for full usage documentation check that `RedHat link` above.

Run the installation process using BIOS(I didn't find a boot window using UEFI where I can press the `Tab` key) and press `Tab`:

#figure(image("/public/assets/img/2021/01/boot-menu.png"), caption: "Boot menu")

In that command at the bottom, append the `inst.dd` option and hit `Enter`.

Follow the interactive prompt and select your driver to install. When you're done, you'll get into the normal installation GUI.

Now go to `Installation Destination` section, you'll find that your disks show up!

#figure(image("/public/assets/img/2021/01/destination-with-raid.png"), caption: "Installation Destination with RAID")

Now you can tap in to normal installation process. When the installation is complete and reboot the system, that driver will be included in the system you just installed. Enjoy
