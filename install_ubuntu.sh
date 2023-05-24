#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2365412586"
MD5="7530596998bb2ca99b69c1b05d520571"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="Next Generation Minecraft Installer (Ubuntu Server)"
script="./install_server"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="."
filesizes="5323"
keep="y"
nooverwrite="n"
quiet="n"
accept="n"
nodiskspace="n"
export_conf="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

if test -d /usr/xpg4/bin; then
    PATH=/usr/xpg4/bin:$PATH
    export PATH
fi

if test -d /usr/sfw/bin; then
    PATH=$PATH:/usr/sfw/bin
    export PATH
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt" | more
    if test x"$accept" != xy; then
      while true
      do
        MS_Printf "Please type y to accept, n otherwise: "
        read yn
        if test x"$yn" = xn; then
          keep=n
          eval $finish; exit 1
          break;
        elif test x"$yn" = xy; then
          break;
        fi
      done
    fi
  fi
}

MS_diskspace()
{
	(
	df -kP "$1" | tail -1 | awk '{ if ($4 ~ /%/) {print $3} else {print $4} }'
	)
}

MS_dd()
{
    blocks=`expr $3 / 1024`
    bytes=`expr $3 % 1024`
    dd if="$1" ibs=$2 skip=1 obs=1024 conv=sync 2> /dev/null | \
    { test $blocks -gt 0 && dd ibs=1024 obs=1024 count=$blocks ; \
      test $bytes  -gt 0 && dd ibs=1 obs=1024 count=$bytes ; } 2> /dev/null
}

MS_dd_Progress()
{
    if test x"$noprogress" = xy; then
        MS_dd $@
        return $?
    fi
    file="$1"
    offset=$2
    length=$3
    pos=0
    bsize=4194304
    while test $bsize -gt $length; do
        bsize=`expr $bsize / 4`
    done
    blocks=`expr $length / $bsize`
    bytes=`expr $length % $bsize`
    (
        dd ibs=$offset skip=1 2>/dev/null
        pos=`expr $pos \+ $bsize`
        MS_Printf "     0%% " 1>&2
        if test $blocks -gt 0; then
            while test $pos -le $length; do
                dd bs=$bsize count=1 2>/dev/null
                pcent=`expr $length / 100`
                pcent=`expr $pos / $pcent`
                if test $pcent -lt 100; then
                    MS_Printf "\b\b\b\b\b\b\b" 1>&2
                    if test $pcent -lt 10; then
                        MS_Printf "    $pcent%% " 1>&2
                    else
                        MS_Printf "   $pcent%% " 1>&2
                    fi
                fi
                pos=`expr $pos \+ $bsize`
            done
        fi
        if test $bytes -gt 0; then
            dd bs=$bytes count=1 2>/dev/null
        fi
        MS_Printf "\b\b\b\b\b\b\b" 1>&2
        MS_Printf " 100%%  " 1>&2
    ) < "$file"
}

MS_Help()
{
    cat << EOH >&2
${helpheader}Makeself version 2.4.0
 1) Getting help or info about $0 :
  $0 --help   Print this message
  $0 --info   Print embedded info : title, default target directory, embedded script ...
  $0 --lsm    Print embedded lsm entry (or no LSM)
  $0 --list   Print the list of files in the archive
  $0 --check  Checks integrity of the archive

 2) Running $0 :
  $0 [options] [--] [additional arguments to embedded script]
  with following options (in that order)
  --confirm             Ask before running embedded script
  --quiet		Do not print anything except error messages
  --accept              Accept the license
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --nodiskspace         Do not check for available disk space
  --target dir          Extract directly to a target directory (absolute or relative)
                        This directory may undergo recursive chown (see --nochown).
  --tar arg1 [arg2 ...] Access the contents of the archive through the tar command
  --                    Following arguments will be passed to the embedded script
EOH
}

MS_Check()
{
    OLD_PATH="$PATH"
    PATH=${GUESS_MD5_PATH:-"$OLD_PATH:/bin:/usr/bin:/sbin:/usr/local/ssl/bin:/usr/local/bin:/opt/openssl/bin"}
	MD5_ARG=""
    MD5_PATH=`exec <&- 2>&-; which md5sum || command -v md5sum || type md5sum`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which md5 || command -v md5 || type md5`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which digest || command -v digest || type digest`
    PATH="$OLD_PATH"

    SHA_PATH=`exec <&- 2>&-; which shasum || command -v shasum || type shasum`
    test -x "$SHA_PATH" || SHA_PATH=`exec <&- 2>&-; which sha256sum || command -v sha256sum || type sha256sum`

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 588 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
		if test -x "$SHA_PATH"; then
			if test x"`basename $SHA_PATH`" = xshasum; then
				SHA_ARG="-a 256"
			fi
			sha=`echo $SHA | cut -d" " -f$i`
			if test x"$sha" = x0000000000000000000000000000000000000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded SHA256 checksum." >&2
			else
				shasum=`MS_dd_Progress "$1" $offset $s | eval "$SHA_PATH $SHA_ARG" | cut -b-64`;
				if test x"$shasum" != x"$sha"; then
					echo "Error in SHA256 checksums: $shasum is different from $sha" >&2
					exit 2
				else
					test x"$verb" = xy && MS_Printf " SHA256 checksums are OK." >&2
				fi
				crc="0000000000";
			fi
		fi
		if test -x "$MD5_PATH"; then
			if test x"`basename $MD5_PATH`" = xdigest; then
				MD5_ARG="-a md5"
			fi
			md5=`echo $MD5 | cut -d" " -f$i`
			if test x"$md5" = x00000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded MD5 checksum." >&2
			else
				md5sum=`MS_dd_Progress "$1" $offset $s | eval "$MD5_PATH $MD5_ARG" | cut -b-32`;
				if test x"$md5sum" != x"$md5"; then
					echo "Error in MD5 checksums: $md5sum is different from $md5" >&2
					exit 2
				else
					test x"$verb" = xy && MS_Printf " MD5 checksums are OK." >&2
				fi
				crc="0000000000"; verb=n
			fi
		fi
		if test x"$crc" = x0000000000; then
			test x"$verb" = xy && echo " $1 does not contain a CRC checksum." >&2
		else
			sum1=`MS_dd_Progress "$1" $offset $s | CMD_ENV=xpg4 cksum | awk '{print $1}'`
			if test x"$sum1" = x"$crc"; then
				test x"$verb" = xy && MS_Printf " CRC checksums are OK." >&2
			else
				echo "Error in checksums: $sum1 is different from $crc" >&2
				exit 2;
			fi
		fi
		i=`expr $i + 1`
		offset=`expr $offset + $s`
    done
    if test x"$quiet" = xn; then
		echo " All good."
    fi
}

UnTAR()
{
    if test x"$quiet" = xn; then
		tar $1vf -  2>&1 || { echo " ... Extraction failed." > /dev/tty; kill -15 $$; }
    else
		tar $1f -  2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    fi
}

finish=true
xterm_loop=
noprogress=n
nox11=n
copy=none
ownership=y
verbose=n

initargs="$@"

while true
do
    case "$1" in
    -h | --help)
	MS_Help
	exit 0
	;;
    -q | --quiet)
	quiet=y
	noprogress=y
	shift
	;;
	--accept)
	accept=y
	shift
	;;
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 92 KB
	echo Compression: gzip
	echo Date of packaging: Wed May 24 14:14:28 UTC 2023
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--notemp\" \\
    \".\" \\
    \"install_ubuntu.sh\" \\
    \"Next Generation Minecraft Installer (Ubuntu Server)\" \\
    \"./install_server\""
	if test x"$script" != x; then
	    echo Script run after extraction:
	    echo "    " $script $scriptargs
	fi
	if test x"" = xcopy; then
		echo "Archive will copy itself to a temporary location"
	fi
	if test x"n" = xy; then
		echo "Root permissions required for extraction"
	fi
	if test x"y" = xy; then
	    echo "directory $targetdir is permanent"
	else
	    echo "$targetdir will be removed after extraction"
	fi
	exit 0
	;;
    --dumpconf)
	echo LABEL=\"$label\"
	echo SCRIPT=\"$script\"
	echo SCRIPTARGS=\"$scriptargs\"
	echo archdirname=\".\"
	echo KEEP=y
	echo NOOVERWRITE=n
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=92
	echo OLDSKIP=589
	exit 0
	;;
    --lsm)
cat << EOLSM
No LSM.
EOLSM
	exit 0
	;;
    --list)
	echo Target directory: $targetdir
	offset=`head -n 588 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 588 "$0" | wc -c | tr -d " "`
	arg1="$2"
    if ! shift 2; then MS_Help; exit 1; fi
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
    --check)
	MS_Check "$0" y
	exit 0
	;;
    --confirm)
	verbose=y
	shift
	;;
	--noexec)
	script=""
	shift
	;;
    --keep)
	keep=y
	shift
	;;
    --target)
	keep=y
	targetdir="${2:-.}"
    if ! shift 2; then MS_Help; exit 1; fi
	;;
    --noprogress)
	noprogress=y
	shift
	;;
    --nox11)
	nox11=y
	shift
	;;
    --nochown)
	ownership=n
	shift
	;;
    --nodiskspace)
	nodiskspace=y
	shift
	;;
    --xwin)
	if test "n" = n; then
		finish="echo Press Return to close this window...; read junk"
	fi
	xterm_loop=1
	shift
	;;
    --phase2)
	copy=phase2
	shift
	;;
    --)
	shift
	break ;;
    -*)
	echo Unrecognized flag : "$1" >&2
	MS_Help
	exit 1
	;;
    *)
	break ;;
    esac
done

if test x"$quiet" = xy -a x"$verbose" = xy; then
	echo Cannot be verbose and quiet at the same time. >&2
	exit 1
fi

if test x"n" = xy -a `id -u` -ne 0; then
	echo "Administrative privileges required for this archive (use su or sudo)" >&2
	exit 1	
fi

if test x"$copy" \!= xphase2; then
    MS_PrintLicense
fi

case "$copy" in
copy)
    tmpdir="$TMPROOT"/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
    mkdir "$tmpdir" || {
	echo "Could not create temporary directory $tmpdir" >&2
	exit 1
    }
    SCRIPT_COPY="$tmpdir/makeself"
    echo "Copying to a temporary location..." >&2
    cp "$0" "$SCRIPT_COPY"
    chmod +x "$SCRIPT_COPY"
    cd "$TMPROOT"
    exec "$SCRIPT_COPY" --phase2 -- $initargs
    ;;
phase2)
    finish="$finish ; rm -rf `dirname $0`"
    ;;
esac

if test x"$nox11" = xn; then
    if tty -s; then                 # Do we have a terminal?
	:
    else
        if test x"$DISPLAY" != x -a x"$xterm_loop" = x; then  # No, but do we have X?
            if xset q > /dev/null 2>&1; then # Check for valid DISPLAY variable
                GUESS_XTERMS="xterm gnome-terminal rxvt dtterm eterm Eterm xfce4-terminal lxterminal kvt konsole aterm terminology"
                for a in $GUESS_XTERMS; do
                    if type $a >/dev/null 2>&1; then
                        XTERM=$a
                        break
                    fi
                done
                chmod a+x $0 || echo Please add execution rights on $0
                if test `echo "$0" | cut -c1` = "/"; then # Spawn a terminal!
                    exec $XTERM -title "$label" -e "$0" --xwin "$initargs"
                else
                    exec $XTERM -title "$label" -e "./$0" --xwin "$initargs"
                fi
            fi
        fi
    fi
fi

if test x"$targetdir" = x.; then
    tmpdir="."
else
    if test x"$keep" = xy; then
	if test x"$nooverwrite" = xy && test -d "$targetdir"; then
            echo "Target directory $targetdir already exists, aborting." >&2
            exit 1
	fi
	if test x"$quiet" = xn; then
	    echo "Creating directory $targetdir" >&2
	fi
	tmpdir="$targetdir"
	dashp="-p"
    else
	tmpdir="$TMPROOT/selfgz$$$RANDOM"
	dashp=""
    fi
    mkdir $dashp "$tmpdir" || {
	echo 'Cannot create target directory' $tmpdir >&2
	echo 'You should try option --target dir' >&2
	eval $finish
	exit 1
    }
fi

location="`pwd`"
if test x"$SETUP_NOCHECK" != x1; then
    MS_Check "$0"
fi
offset=`head -n 588 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 92 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
	
    # Decrypting with openssl will ask for password,
    # the prompt needs to start on new line
	if test x"n" = xy; then
	    echo
	fi
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf "$tmpdir"; eval $finish; exit 15' 1 2 3 15
fi

if test x"$nodiskspace" = xn; then
    leftspace=`MS_diskspace "$tmpdir"`
    if test -n "$leftspace"; then
        if test "$leftspace" -lt 92; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (92 KB)" >&2
            echo "Use --nodiskspace option to skip this check and proceed anyway" >&2
            if test x"$keep" = xn; then
                echo "Consider setting TMPDIR to a directory with more free space."
            fi
            eval $finish; exit 1
        fi
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
		fi
    else
		echo >&2
		echo "Unable to decompress $0" >&2
		eval $finish; exit 1
    fi
    offset=`expr $offset + $s`
done
if test x"$quiet" = xn; then
	echo
fi

cd "$tmpdir"
res=0
if test x"$script" != x; then
    if test x"$export_conf" = x"y"; then
        MS_BUNDLE="$0"
        MS_LABEL="$label"
        MS_SCRIPT="$script"
        MS_SCRIPTARGS="$scriptargs"
        MS_ARCHDIRNAME="$archdirname"
        MS_KEEP="$KEEP"
        MS_NOOVERWRITE="$NOOVERWRITE"
        MS_COMPRESS="$COMPRESS"
        export MS_BUNDLE MS_LABEL MS_SCRIPT MS_SCRIPTARGS
        export MS_ARCHDIRNAME MS_KEEP MS_NOOVERWRITE MS_COMPRESS
    fi

    if test x"$verbose" = x"y"; then
		MS_Printf "OK to execute: $script $scriptargs $* ? [Y/n] "
		read yn
		if test x"$yn" = x -o x"$yn" = xy -o x"$yn" = xY; then
			eval "\"$script\" $scriptargs \"\$@\""; res=$?;
		fi
    else
		eval "\"$script\" $scriptargs \"\$@\""; res=$?
    fi
    if test "$res" -ne 0; then
		test x"$verbose" = xy && echo "The program '$script' returned an error code ($res)" >&2
    fi
fi
if test x"$keep" = xn; then
    cd "$TMPROOT"
    /bin/rm -rf "$tmpdir"
fi
eval $finish; exit $res
�     �=�W�H��YE#�	��26>v���s��xl�m&�7��'�6֠ã�ē/��V���L��Q'/DjuuUuwu]�h�g�^v�4�M�Yi�w�?eyV����j�z�R{�[�4�g���J��O�3�3i0�z�w��?Ѣ�����ް�9�}��Ѹj����d���
��^��������;"G�A݀*ʡ7����$$��Rݭ>�Lr��3�ܶtE9��c���
Ȅ��lN�}���C�>��c���t����9�R?��Y�[���З_� x��R�)|l=<��1=#r��!�7�l��pB�:-����b��d���ħA�[��!�kؑ�8�j�r,�6g @�Cϴ���2��љm�bZ�,
�e�/'w���瓀ڶ,��њ`ǾAԧ��P�(�7���Rb�8�]蒲6�,c=�A����c϶�K$��\�B��}EA�~��(����녀*G`����
&�m�3*�{�9>v��-�&S�g�-��A�o;d�=z�tHwHN�_��N���!<�;�]w��:"�Š��'�פ�{O���wH�'��pH��{|r����n�����!��]���S���;���!;���c�U��;z����z�u@Z�5uO�Zrr:8�;�}������s��4�ޑί�@�o[GGؕ�:��9쟼t߼����v^�� f�WG�ux���v����Z��@��8v������Z��p������~o4���r0����;;�5��!����	-���u8d5Ɍ|�ϧ�N��;�#�5��H��XS��;���Ϩ��L7.�i����f�~#�����ze���c��6�8�l������X�F��(���(#���/��|
����Ux�4
��[.5|}>[�}��Y��+��?�}x���[��!k���J���ln��,�|�Ű��+ԘxD}Gm�s�4-z�SH�P���PJB�O�o��5&�}��R	�3'��C:%�&)�� (W!�w������.X`߁92�m0813Y�9��B{D�45r�8�,J!
3ѐ��
����Z����b�K^/.D��*c��q�d*�H�D�ȏ���Ige7��ƴ��Y��#��5�`M�:|���uI��j��嚔`�Ǣbs��1(��i�p�,=���͛P�rk�6iۼ���|�6y�@�Ou k
�q���ҋl�̽���������x�k�}��+�^������"�x��rx�6
��!6g'�M�L�9k9\����m�T�;�a�SR_ȯ~:����֠�k����H�0��#�~�Q��xs_\�U ��1	o�K�DƄ8�A�wy���
х��l�y���V�0��%[��\�m������~�;���a�H�J��ɦ�F���i�7�d�����A�6p���-{.̈́�H2�`�^�/2T�+���p��6"{s��YU.�9�Y��/�ʜ�{��Nw`�E������{p�\�=��wU%�|.�oMà�I�c 30 Ĕ� ��r��CP�G���f�d�� 2�	����+p�>x�U�s��ux�,@X	�}�i@õp� �
�>��`@����u�O�^�s�����ᔏ0�c�|$r���Lt�5�+29P�A&�g��#�|��Cݿ���o:B�����#���	�N���
�mw��řI�B���+�V,m�J��a�	���R������:���}�\��߫W����Z���=��/����r�uW?�D�![d��S��\`m��	��C�;@�l�9��4$�RȀ h4�,�8��4�H�r��$WcF�nLh�����(�h�����p_)�S�� �l�H�m|�z��(�j\0�e@��  ��Q[,0=��X^ťk{`SjXcː����YD��!�YM���4�/����L3<t0����G��8[��,�����l�c�v0�]*�_�����a���9�y#B���XE9^����)��;"� �5��hySԉu[#�1�X0]F�K�x<�C�O����ǟ���;�L0$y͵x�9'z�g�PB�Q��#��Բt�4r��5���"��̐&7��aF
��Ϫ�K�Xۗ���2ܵ?`�[�n��>��| ��L@�19�-Ƅ̄���)���ԙ�,sI����lg@�Ps�����^�{<7�=9�ses#�l3^>�5[���#���#�4&�{��,�?��0jg^8�^�M6�X�8ª��&��Xq("�-A�K
3gY�dЖUbX|�M}ofa�C&&F�I�1�2�Y"˱㓛��R����&�
��E��M��$=(��r;d�"���2�!����J�%���C�؞��$�$��q6��B���;i5�X�l�W�Ԙ��悀G!J-��c���)c>�Y����/�p�d�7��vW�'J�;dIS��>��qav���3򩏌b�9Vt!h�� &�%cH��&ut�"����FI
�c-&'�]��Cw�lS��jD�rC��xB��XǾ�����4j�L����"���?�4:��\�z�V-��ǌ�s-�L���*�{�Qg���!!��ތ��a`S�"�yQ;�p�[ h��v�|���qu/�d�'X�g�?�iβ����1O(n����o�d�����*Vxӥ�{�u���v��l[�ŋ��j qᝀ��D�i[	ο�?��"���V�.�n��`~��B}�3Hɧb�D�+������L;V������gFđZ,��|�3Pʉ��9`��\]��,{ޥ��vp��:���|%
n�/H��Iv�(�v��[�y��<��������olu���)���浼�K^��0�	�Mm��8�G�W����M��c_-�H��`#!�˯0�!CB0^J������2?�v�� �XU~,ʤ��*�ѓ��r��Ȉ�ʼ�^�z~|d'���͝��?��(����2eA���!�/��̀KE�q���<I㜉؃���$󀜱[�Ʒ2��)S΀�B0�T�sN �)�w�z:{f����:�;��	���%H�U�j���s+6��2���G�i��s�ۮ�zI,ߪq&��^[�]۔��vs��m d7�[���^�k�97r6�xYfur*�5(�0����VY2�ʃmBc�%�<��l,/FvZOT��ӛ9�p�TC�3A�8b�hr:8B!�~�|>bi�[♔��Z'$aö`��\�i�"�P��.�zJ0�4�2@���b$S�5�R��>���8���Ϝ���2��b�؊}s�,��wT�M_w�N�M&�Mg��gU8<�b�3�0k�{�?'� 0F`�;�J�$ߦY��VB��ɯ%)� �vP�d�1�D!.��@��_'cX�"h��\�E���2����H�\��oB�];��ɨ�<�86K7�I����ϘW���m���?����(�h����Ӿ{��h֋���T��1uXUf�а�� }�ӆ�0|��H��`����%��؜��r&+�����D�rA}��A�kXC#[��D7�߼)u�j-�����zl�c���)h�*��#���.�X��n��`���G�5F'�H��&y�E:����y�Ī�8��4��&c��޼�e�l
���"���� �Nx�0�}9�Ƚ�| �HӔU&?.�_�S�)�������yd)l����!H��mjyָ���\T�8�W(����y�$���B�_s�R��=��ƚ
�d���E8r)�ٰ�����E�ӳ=(��j���/��Bn$�$0����YK��@j�H���4�ڊe�[3�Ɲ�IՈY$2�W9q�'�Ѣ2�Ω�hK��M�=ߧ����X�Z6
�9<R'iG��x�\�p�(Tq�ߺ�:'�@��n}���fe���xR����K�,��8q�A(�aƑ�:
�k�.�<ݨ8�K���������h-|�hZ��E1��]A���e�:�1�]�]��|���7�����{��*Յ�_ݭW��_���O���Ծ�;�9�I�j�&9�|�o�39^��}����&��i��5�G1��v������:���AQ�;`��՜d�3��ˏ�]��Bf�f.ݾ{@���Xp�q<n�!/4�'��-$}<��_����f���OD���[PS+v	���4��h�?gz!���P7&�rY�UU�a���{�4����Y_H�����Rh�)% ��'j�u(%�|�B~����0��6�$?�?�����U�X}�5T��_�#����\����9>�/[������X��}�7���3�'ޕ�ׄ�(eߩ+]��X~<��M�{��Q]���B�?)�_������aƔ���ӳ�ݡx"��
�������  ����O�x�����	��\�����<��O�&�����?�5��(��Z�"}���t��'����mlld���G�Y|�l�F�!�B˶��<���];>r��b8���i��l�+1P~Y �X@rHe�u���.A#�L���������]C��'�DIz/��3Nr�N��Q�P�:��3�1gSK��gj��g�cp��9x�t�{uB�L((���]���B��ޖ�l��G�-��*�%ݔ+z�������i��2�t����KT�JP�Q��KM-�]����ԉ{���zu��[����=��׊�-ݿ��K%�UK���T��s��eR<�Y�A[��݁D�U@|��u댾1>û�#Κ,�=㫯�|���^�����?<M���f=��
�SR�[A�Tӊ�m�?��Z�{׮��ɬ��ǵ��{K�J��������o���="�� �|Kټ�,d�
x��\+�B	F�������<g �/c1���I����E��We����/hCOHH���>ů�*���7��w�k�?���w���E�?g��?C�`���MB�� w�����_������V�,�������)���;�Bxٵ8�|vTLGƯ�k����K��yzy��} m��)>c���_�=����� !���*f��������y�<�i���Cd�;6qgX2�1����ĉx-���mq��m���ĺ������g�J�W��&$�0[���z3�`n!U� ;�VƜ�ˍ��o'�i��z�gUҷ�(VS(|�y���(E)JQ�R���(E)JQ�R���(E)JQ��,��U�A �  