%%sign%%
C'est l'heure de la récréation … GPG
------------------------------------
<small>2015-05-23 par fridim ~ #gpg</small>

Index:

%%TOC%%

---

Il y a beaucoup d'articles traitant déjà ces sujets : création de clef GPG, configuration d'une Yubikey, etc. Cette page «compilation» contient mes notes des différentes étapes par lesquelles je suis passé pour générer une [nouvelle](/files/transition_statement_2015-05-23.clearsigned.txt) clef GPG. [Liens](#liens) à la fin.


**Objectif** : créer une nouvelle masterkey et ses subkeys. La masterkey restera *offline*. Les subkeys servent à l'usage de tous les jours pour signer ou déchiffrer des messages.

**Étapes** :

1. créer un livecd
1. générer les clefs sur la machine *offline*
1. backups
1. signer son ancienne clef avec la nouvelle et vice versa
1. préparer une clef usb pour ~/.gnupg de tous les jours
1. publier sur les serveurs de clefs, [keybase.io](https://keybase.io), etc

Au final, 2 clefs USB:

* une qui fera office de livecd avec la masterkey
* une qui contiendra le `$GNUPGHOME` avec les « daily subkeys »

## Création du livecd OpenBSD
Étapes décrites dans un post précedent : [livebsd](/notes/livebsd.html).

Les commandes en vrac avec la dernière version d'OpenBSD :

    ::::bash
    wget http://ftp.fr.openbsd.org/pub/OpenBSD/5.7/amd64/install57.iso
    sha256sum install57.iso # -> 3f714d249a6dc8f40c2fc2fccea8ef9987e74a2b81483175d081661c3533b59a
    qemu-img create liveusb.img 1525000k # we can allocate more space
    qemu-system-x86_64 -hda liveusb.img -smp 2 -m 6000 -cdrom install57.iso # you may want to use less memory
    # Install starts...

Une fois l'installation terminée, reboot de la VM puis install/setup de quelques paquets. Dans la VM:

    ::::bash
    export PKG_PATH=http://ftp.fr.openbsd.org/pub/OpenBSD/5.7/packages/amd64/
    pkg_add gnupg bash rxvt-unicode vim # for example
    chsh -s /usr/local/bin/bash fridim
    cat > /home/fridim/.xsession <<EOF
    #!/bin/sh
    export LC_CTYPE="en_US.UTF-8"
    export LANG="en_US.UTF-8"
    setxkbmap -option compose:ralt &
    urxvt &
    fvwm
    EOF
    chmod +x /home/fridim/.xsession
    export GNUPGHOME=/home/fridim/.gnupg
    mkdir $GNUPGHOME
    cat > $GNUPGHOME/gpg.conf <<EOF
    default-preference-list SHA512 SHA384 SHA256 SHA224 AES256 AES192 CAMELLIA256 CAMELLIA192 TWOFISH AES ZLIB BZIP2 ZIP
    cert-digest-algo SHA512
    personal-digest-preferences SHA512 SHA384 SHA256 SHA224
    use-agent
    lock-never
    charset utf-8
    EOF
    shutdown -h now

On copie l'image sur la clef USB :

    ::::bash
    sudo dd if=liveusb.img of=/dev/sdc bs=512k ; sync # replace /dev/sdc with your usb stick device
    qemu-system-x86_64 -hda /dev/sdc  # test to see if it boot

À ce stade on a un livecd avec le minimum de paquet (dont gnupg) et de configuration.

## Préparer la machine offline
Pour se la jouer vraiment (trop ?) sérieux, il y a ce [blog post](https://paulfurley.com/gpg-for-humans-preparing-an-offline-machine/) qui va assez loin. Notamment :

* livecd sur une clef USB readonly
* enlever physiquement tout support physique de la machine (disques durs/ssd)
* enlever physiquement et/ou désactiver dans le BIOS les interfaces réseaux (wifi, ethernet, bluetooth, ...)
* clef GPG sur une clef USB chiffrée (LUKS par ex)

Ma première idée de machine air-gapped, était d'utiliser un raspberryPi dont je ne me sert plus. Puis cherchant si OpenBSD pouvait tourner dessus, je suis tombé sur ce [mail](https://marc.info/?l=openbsd-misc&m=132788027403910&w=2) assez décourageant de Theo de Raadt.

## Génération de la clef
![dice](https://lut.im/xYgPD8s6/2fJ47qbK)

Avant tout, [bien choisir sa passphrase](http://world.std.com/~reinhold/diceware.html).


Je démarre la machine offline (un vieux laptop qui traîne finalement) avec le livecd OpenBSD pour générer la clef.
Il est possible de passer des paramètres à GnuPG grâce à l'option [`--batch`](https://www.gnupg.org/documentation/manuals/gnupg/Unattended-GPG-key-generation.html#Unattended-GPG-key-generation). Voici ce que j'ai choisi comme options pour ma masterkey :

    ::::bash
    cat > masterkey_params <<PARAMS
    %echo Generating a masterkey
    Key-Type: RSA
    Key-Length: 3936
    Key-Usage: sign
    Name-Real: Guillaume Coré
    Name-Comment:
    Name-Email: fridim@onfi.re
    Preferences: SHA512 SHA384 SHA256 SHA224 AES256 AES192 CAMELLIA256 CAMELLIA192 TWOFISH AES ZLIB BZIP2 ZIP
    Expire-Date: 1y
    %ask-passphrase
    %commit
    %echo done
    PARAMS
    gpg2 --batch --gen-key masterkey_params

Pour la taille de 3936, je me base sur l'hypothèse que l'effort pour cracker une clef RSA serait concentré sur l'habituel taille en puissance de 2 (1024, 2048, 4096). C'est parfaitement infondé, mais il n'y a pas de contre-indication, alors pourquoi pas ? Concernant les préférences, c'est assez classique des « best practices » sauf que j'ai déplacé [AES](http://en.wikipedia.org/wiki/Advanced_Encryption_Standard) (128 bits) pour le mettre en dernière position. [D'après la NSA](http://csrc.nist.gov/groups/ST/toolkit/documents/aes/CNSS15FS.pdf) il y a une différence de SECRET à TOP SECRET (???) entre AES 128 et 192 mais rien de tel pour CAMELIA au niveau des différentes tailles de clef :

> Even using the smaller key size option (128 bits) [of CAMELIA], it's considered infeasible to break it by brute-force attack on the keys with current technology. There are no known successful attacks that weaken the cypher considerably.

À ce niveau là, je pense que c'est du chipotage et surtout que AES256 sera supporté par toutes les implémentations (GnuPG en tout cas).

Je ne savais pas que le champs Comment des UID était considéré dangereux par [certains](https://www.debian-administration.org/users/dkg/weblog/97). Je pense qu'on peut quand meme l'utiliser pour son nickname lorsqu'il n'est pas déjà visible dans l'adresse mail. Mon nickname servant pour IRC/github/twitter/etc, ça fait du sens.

Exemple de sortie :

    plop:~/tmp/gpgtests$ gpg2 --batch --gen-key params
    gpg: Generating a masterkey
    gpg: key 722F12DA marked as ultimately trusted
    gpg: directory '/home/fridim/tmp/gpgtests/openpgp-revocs.d' created
    gpg: done

    plop:~/tmp/gpgtests$ gpg2 --edit-key fridim
    gpg (GnuPG) 2.1.3; Copyright (C) 2015 Free Software Foundation, Inc.
    This is free software: you are free to change and redistribute it.
    There is NO WARRANTY, to the extent permitted by law.

    Secret key is available.

    gpg: checking the trustdb
    gpg: 3 marginal(s) needed, 1 complete(s) needed, PGP trust model
    gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
    gpg: next trustdb check due at 2016-05-13
    pub  rsa3936/722F12DA
         created: 2015-05-23  expires: 2016-05-13  usage: SC
         trust: ultimate      validity: ultimate
    [ultimate] (1). Guillaume Coré <fridim@onfi.re>

    gpg> showpref
    [ultimate] (1). Guillaume Coré <fridim@onfi.re>
         Cipher: AES256, AES192, CAMELLIA256, CAMELLIA192, TWOFISH, AES, 3DES
         Digest: SHA512, SHA384, SHA256, SHA224, SHA1
         Compression: ZLIB, BZIP2, ZIP, Uncompressed
         Features: MDC, Keyserver no-modify


<div class="warning">
<p>Les accents dans le nom ! J'ai passé beaucoup de temps à comprendre pourquoi après la création réussie, j'avais des erreurs à l'utilisation de la clef (signature / key-edit / ...) du style:</p>

   <pre>gpg: signing failed: Operation cancelled</pre>

<p>Supprimer les accents du champ Name-Real résout évidemment le souci. Mais on peut les conserver. Il faut juste penser à :</p>
<ul>
<li> Avoir les bonnes variables d'environnement.</li>
<li> Se méfier de vim. Bien penser à <code>:set encoding=utf8</code> si vous éditez le fichier params à la main plutôt qu'avec <code>cat</code>.</li>
<li> Préciser dans <code>gpg.conf</code> l'option :
    <pre>charset utf-8</pre></li>
</ul>

</div>

Puis on génère les sous-clefs utilisées pour l'usage courant :

    ::::bash
    gpg2 --command-fd=0 --edit-key fridim <<-COMMANDS
    addkey
    4
    4096
    1y
    addkey
    6
    4096
    1y
    save
    COMMANDS

### Expiration date
Une petite note au sujet de la date d'expiration : mettre une date d'expiration <2y. En effet, une date d'expiration peut toujours être **étendue** si besoin! Penser juste à mettre une alerte dans son calendrier à la date voulue pour penser à l'étendre. Pour mettre à jour la date d'expiration de sa masterkey :

    :::bash
    gpg2 --command-fd=0 --edit-key '<fingerprint>' <<-COMMANDS
    key 1
    expire
    2y
    save
    COMMANDS
    gpg2 -a --export '<fingerprint>' > /mnt/TRANSPORT_usbstick/masterkey.pub.asc
    # on the online machine :
    gpg2 --import < /mnt/TRANSPORT_usbstick/masterkey.pub.asc
    gpg2 --keyserver keys.gnupg.net --send-key '<fingerprint>'

### Backups et certificat de révocation
On créé tout de suite le certificat de révocation et un backup :

    :::bash
    mkdir -p ~/backups
    cd backups
    gpg2 --output revocation-certificate-A9903389.asc --gen-revoke A9903389!
    gpg2 --armor --export-secret-key A9903389! > masterkey-A9903389.asc
    gpg2 --armor --export-secret-subkeys A9903389 > subkeys-A9903389.asc
    gpg2 --armor --export A9903389 > pub-A9903389.asc
    # vérifier le contenu :
    gpg2 --list-packets < masterkey-A9903389.asc
    # vérifier qu'il s'agit bien du packet OpenPGP dummy pour la masterkey :
    gpg2 --list-packets < subkeys-A9903389.asc
    cd
    tar czvf ~/backups/gnupg_masterkey.tar.gz .gnupg

## Préparer la clef USB daily

La clef USB va servir à stocker les « daily » subkeys (le dossier .gnupg)

Je vais l'apporter souvent avec moi notamment dans mes déplacements. J'ai décidé de :

* chiffrer avec LUKS toute la clef USB
* FS ext4 (pas FAT32)

Cette protection n'empêchera pas de devoir révoquer les subkeys si je perd cette clef USB, mais c'est une protection supplémentaire pour peu d'efforts en plus.

    :::bash
    usbstick=/dev/sdb #or whatever it is
    # user root (or sudo)
    cryptsetup luksFormat --key-size 512 --hash sha512 --iter-time 5000 $usbstick
    cryptsetup luksDump $usbstick
    cryptsetup luksOpen $usbstick dailysubkeys
    mkfs.ext4 /dev/mapper/dailysubkeys

Plus d'info sur les options pour <code>luksFormat</code> : [wiki Arch](https://wiki.archlinux.org/index.php/Dm-crypt/Device_encryption#Encryption_options_for_LUKS_mode)

### Automount au boot
On chiffre mais il faut quand même que ce soit utilisable au quotidien. Pour ça, mettre à jour <code>/etc/crypttab</code> et <code>/etc/fstab</code>

    :::bash
    # user root (or sudo)
    usbstick=/dev/sdb #or whatever it is
    uuid=$(lsblk -f $usbstick --output UUID -n)
    echo "dailysubkeys   UUID=$uuid none nofail,timeout=10" >> /etc/crypttab  #nofail pour ne pas bloquer au boot
    echo "/dev/mapper/dailysubkeys /home/fridim/.gnupg ext4 defaults 0 2" >> /etc/fstab
    # pour éviter le reboot, on peut tenter directement :
    /usr/lib/systemd/system-generators/systemd-cryptsetup-generator  #this will create systemd-cryptsetup@dailysubkeys.service
    systemctl daemon-reload

### Exporter et importer
On peut utiliser une clef USB ou une carte SD pour faire passer les clefs et signatures depuis ou vers la machine offline. Copier sur la clef uniquement les subkeys et la partie publique de la masterkey. Sur le système connecté, vérifier la présence de <code>sec#</code> :

    plop:/$ gpg --list-secret-key
    /home/fridim/.gnupg/pubring.kbx
    -------------------------------
    sec#  rsa3936/0x0A74F4B1A9903389 2015-05-22 [expires: 2016-05-21]
    uid                 [ unknown] Guillaume Coré <fridim@onfi.re>
    uid                 [ unknown] Guillaume Coré (fridim) <gucore@redhat.com>
    uid                 [ unknown] Guillaume Coré (fridim) <guillaume.core@gmail.com>
    ssb   rsa4096/0x2C90D3E4573FD8DE 2015-05-22 [expires: 2016-05-21]
    ssb   rsa4096/0x76F17D8B22049114 2015-05-22 [expires: 2016-05-21]

Pour les unknow il faut en effet mettre à jour les trusts de la clef puisqu'on l'a importée :

    gpg2 --edit-key 0A74F4B1A9903389
    trust
    gpg2 --list-keys 0A74F4B1A9903389
    sec#  rsa3936/0x0A74F4B1A9903389 2015-05-22 [expires: 2016-05-21]
    uid                 [ultimate] Guillaume Coré <fridim@onfi.re>
    uid                 [ultimate] Guillaume Coré (fridim) <gucore@redhat.com>
    uid                 [ultimate] Guillaume Coré (fridim) <guillaume.core@gmail.com>
    ssb   rsa4096/0x2C90D3E4573FD8DE 2015-05-22 [expires: 2016-05-21]
    ssb   rsa4096/0x76F17D8B22049114 2015-05-22 [expires: 2016-05-21]

## La migration

1. Signer l'ancienne clef et la nouvelle. Sur sa machine courante, si on a déjà importé les subkeys, pour signer la nouvelle clef il faut préciser quelle clef utiliser avec l'option <code>-u ID</code> :

        :::bash
        gpg2 -u <old key> --sign-key <new key>
        # dans mon cas:
        gpg2 -u 3A69792B0483A324 --sign-key 0A74F4B1A9903389

1. Rédiger un « transition statement ». Exemple [ici](http://fifthhorseman.net/key-transition-2007-06-15.txt) et [là](https://we.riseup.net/assets/176898/key%20transition)
1. Signer le statement avec l'ancienne et la nouvelle clef. Pour ça il faut importer son ancienne clef privée sur la machine offline. La signature du transition statement se fait sur la machine offline.

        gpg2 --local-user <NOUVELLE>! --local-user <ANCIENNE> --clearsign transition_statement.txt
        # dans mon cas :
        gpg2 --local-user A9903389! --local-user 0483A324 --clearsign transition_statement.txt

1. Mettre à jour ses signatures / sites / ...
1. Révoquer l'ancienne clef.


## Longévité des données sur une clef USB non utilisée
A priori, on n'utilise pas sa masterkey très souvent. Uniquement dans certains cas:

* signer la clef de quelqu'un d'autre
* revoquer une subkey
* générer une nouvelle subkey
* …

On peut se poser la question, combien de temps les données restent valides et intactes sur une clef USB qu'on n'utilise plus pendant plusieurs mois ?

Il n'y a pas de réponse précise, juste une fourchette estimée « quelques jours à plusieurs centaines d'années ».

Wikipedia:
> Estimation of flash memory endurance is a challenging subject that depends on the SLC/MLC/TLC memory type, size of the flash memory chips, and actual usage pattern. As a result, a USB flash drive can last from a few days to several hundred years. → [Source](http://blog.bowtiepromotions.com/2013/04/how-long-does-a-usb-flash-drive-last-part-ii/)

Nous voilà bien avancés ! Bref, on fait un backup. Sur un autre support de préférence, pour être tranquil. Par exemple pour un backup du dernier espoir : imprimer (sur papier) sa private key avec [paperkey](http://www.jabberwocky.com/software/paperkey/). Paperkey permet d'imprimer uniquement les bits de la secret key (ceux qui nous importent pour le backup). Ce qui fait gagner du temps si on doit la recopier :

>  For example, the regular DSA+Elgamal secret key I just tested comes out to 1281 bytes. The secret parts of that (plus some minor packet structure) come to only 149 bytes. It's a lot easier to re-enter 149 bytes correctly.

<hr id="liens" />
## Liens
* [offline GnuPG master key and subkeys on yubikey neo smartcard](http://blog.josefsson.org/2014/06/23/offline-gnupg-master-key-and-subkeys-on-yubikey-neo-smartcard/)
* [the Debian Way](https://wiki.debian.org/Subkeys)
* [the Fedora Way](http://fedoraproject.org/wiki/Creating_GPG_Keys)
* [simplekey](https://github.com/nyarly/simplekey) - Outil pour simplifier l'utilisation de GnuPG. L'équivalent de keybase.io mais sous forme de scripts bash
* [Yubikey PGP documentation](https://developers.yubico.com/PGP/)
* [GPG for humans](https://paulfurley.com/gpg-for-humans-preparing-an-offline-machine/)
* Stackexchange - [What is a good general purpose GnuPG key setup](http://security.stackexchange.com/questions/31594/what-is-a-good-general-purpose-gnupg-key-setup/31598#31598)
* [diceware](http://world.std.com/~reinhold/diceware.html) - générer simplement une passphrase robuste
* [secure yourself part 1](http://viccuad.me/blog/secure-yourself-part-1-airgapped-computer-and-GPG-smartcards/) -  Post de mai 2015
* [OpenPGP best-practices](https://help.riseup.net/en/security/message-security/openpgp/best-practices)
* [about Comment in user ID](https://www.debian-administration.org/users/dkg/weblog/97)
