#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4220618439"
MD5="cc04174284b523ea7cfa079c77e8accd"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="Next Generation Minecraft Installer (Ubuntu Server)"
script="./install_server"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="."
filesizes="16468"
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
	echo Uncompressed size: 116 KB
	echo Compression: gzip
	echo Date of packaging: Wed May 24 12:41:50 UTC 2023
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
	echo OLDUSIZE=116
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
	MS_Printf "About to extract 116 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 116; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (116 KB)" >&2
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
�     �;l$�yN��N�������������;�����]�>�}p�W�x��z�ݙef���s@������h¯��VQZU J���jH��$(ME�*RQtJJ��{o~���w%�T�{���{���{��~�oә���'������ˊ�OG�����7���uds�������;�4mG��(�ej7�� n�����tF7���|s�i8ʹ��;>�^x시_O6�A�������m���؋�v2����.Yz�!+�M�Ԡ���2iںQ%��i�B���t������aSR2���PbѬҢ�L�f�����k8�p�]D�@c��deѬ�ZD7ʴA��p�Y��4����}pj<)I�Ӈ��N���f]����s��ِ�J�!oH>� �I]�F�G�f]�{�}���|o^�&F��!��_����%����/�4:P)�w��Z9���¡aUξˏ,�LLMONΨ�<��T3N��.�Ʀ�nUe��!BW���]�j����Q�ꐃ�Pt� �AK�Vq�a.��"ݳL�I�ZpIY��ʁ�۬��Ѭ��ʲ�R�Yu�m���T+SK���:e�42P�Fm�V
��zs}��DiC�[�d��+��P�C���S�=i�m�G�,��%��w;Ra�R����y��G�jP�:*dɔ�r�h�j�i��T�����U�i�V�YZ��Ң?.��m�=�O>�2G�ڨ��(	���g���A�X�{��=�]Y�C���ؚx�dd�5H��)F���O�#қ�JN�փ1�/ܑ�*We%`�lSɪ�R�	C�$u���pp���[���8V��e�} ����jT��أE�p���AL�f��6$�?��&-���b
d�-?�����ՈR��^Di���`��!�!��`�V�$�Ap�޶N�_�h|b���
I-M��b;�^#�<i+K�k7ڭ��O�Lg&I�ؙ�g� ����d�KJ$�Y�>�,��Ғ���,G2$���y_�tu
]eP� ָ(}�V�<���#&�!Z�e�n%�>��q�)|~��:$Kv�`�=.�}�;� 
\&iG�>���В|� �U�ڶO�����4C@���t��A���p�a�؛Y����[�UgQUz�j2m5�U�ڛ��ۓ��{�^�u�#��u��f�w��9�c0�.Dg�۟ӥ��w�E~_@o���G2�3�1��{���r�v��=�HmR&Ζ��8�	��]p�q��߅�ЉNs�lqsP\P������c��jQ��/�ds�ݶ�d�9b��m?���ݭ�:_�nڴ5���!�%�.�:6b.�Y�f�"�>߃	G4��${�4�^��!��|V��w/�<Dp����/���n'��I.	���ˏ�Ĵ����^0�@�,��'�b��0�:�G�J= 6���Z.C��Z��;5���iEk�q_��3JK�iA$�pC�t:�!��uҎ[�m��E&/L$�!:�c�Xpl�0�����TZ��%BF��8�
Np�g<h��d�iH��B7������T
��rY��2`��:N��D6zF��>*F�+��ED��2�PM��k[��!�� i�V�3#����$l(���Q��pw�88J�����t�fø/��a���#5L�JKaPw:XX��-�J�;$t
#�B R��ݨ�H$pq�#ކ�^4W��}�r�{)�hɬ7�N�Ŵ���/ܷ�HVaUugh���b4�ֻ�XZ	�rΐ��\jZ*�&Dw..�G����
�N�e���qL4�.X���%h����T��l��t(j�� V]��:K:��Z�4`ڪ	�aW6n���ۦ4�R2��$bcU�(�'���0�����(³e6���Q���5��P�-�#��"����� ���6��{Q���\�|�;9>:�B:��t���+�'F��`JV<�AF���=��+�5Z-c۵L����f�� o�_^��~x� F�̀���Qܻ#�iGj]��"����f��<鑊���F��Wn2��[V<�2�m=K�"�w���Wq\�Ȧ���0��k-�l{Qk�S��&�ѭx��V��%��;Q����[�R4Vaj=�&�q�Zz��Y��o�@�d1`qC�"�$e��ݻ�Ht�DR%�H-Lm�D��gb�it��Ϩ���U�����JV	h����� g����IRE/�����.쾸 6�����{pEF~8��v39IiH)c#���[ �.H�Qp6ûM%
k�P#9y���-Ͽ%��t>�AMg��WP�f�7��̜?��<�� &M�ḗ��)6l��D�s��d�(����C����Nao	��1�X��#˵�;�0R�Pf+�Y'���v �h����h'���A(�<��ƜB�X�y�}����X[p�ǹ��%�:����(p%�y\	@[r%>��Mq�i��6��Y�#'X��z��,��{,��߄�ĵ"���.���-���;f��Ԉ�9�DN8��%��~��6�-w�721:?v����q�0��J7�[�jӟ����oiK�I+.����!E�?�k`���g����|T��̂Nv��ʳ���%�N�#�s��X��4nh�4ˁMs֘���P�!BX�-W���f��{X� ����c�_�����v<7�8�!���p*�Ge��K~�C���V(��x�]ew,v���fC���d�^�d6Z��􄐁Z���P[�iS� �{�\�p��f�JK�6���WyV#)%�T�ď>+%�x?u�b�0~֒�*��Sqؘ�/�{[�g8Y� �㍩^�K�6p/\�Pv�g"��yЬ�E����5H���#�� �$�[���>�axW�ȧ��U�E$7�j��-�Kr����`���Ό�|6��:��kOY�'�<�e߳]�@e/��Խ�s<�?'cT��zcN���K[������XM�Z���*��X �%K��d���,�OP_,0�=%�渔��VbJ&���6�}DM�N<�Z�/摈<�♖8�8�E����N��)�����[��0�ʹ�k��;�����I4x��)�1���r���eXF���B��*7�̑y�5>|`l\�s�jΓ�����l�G� �t��� E�ѻSw��G�ƦP������cc�7N�C�Υprbjz�PP	.��� \�q���ǟ�p1�x�[!ĝ-�ؘ��?h)9<����C��]OJ~�x�0!eYԴ��bF趓�P3�'%�c���d".hL`�\���1�#��53����61�	f���%X*y�Ǥ����m�i{p�Hײx7�Ch�~S�E�,+�
3}�s~��G←%����8H��X��F- O�W�"��@��������� �xEY����Fqs`���q��^H, �a��n��'q��r&�ꊎ���en+a!S�/���` J53昋,es��!^-����L��ʵ�߀`��a���o�PI���<�㺤Z0��6ؐ�V%���b>v�����qx!����XV�u~[g7d����ס�����U�1D�W6F�^�i�:wQb=�o7q����Y�@�B�<��x@����xɲAؠ��뺛�(���v�Y6����Dd
x-���n(#�>l����a:w�yߩ7�<�%m���ᣣ��b]ĝrg���Y�<�9�Y��iEa�Kh��j3D,��b�l���BN8O�
����#E�#f(p[<?29u\�f��(5J#�'v{�a��xw��Wm�"���J�u�Lv����F��k�R��~P���A?{��c .�n�)���U!E׷ J�({#�H���Hm�N� �ڮ"�~����
%��tT����K�A���^�m�paj|�8w}]��[�7�vr��E��Sݴ_� ��A�E�da��e;��e�6��]�Y:^t��C񫖛fƦ'
��G��Y�)o��Z]�U9����1��Z)�� ���?.��%p�M�%5˻̚Ym���xǌ����z����W4�/�޵1���m�4��VQ��!��DAɢXskë�4pN���,Ȳ��"�����ֳ]�>�g�J�"�����#/��T�+��W���)�$�j
����(���Px����6,N�
:s�3D(-���aQ���(Qi�<M��Y���#�-_HU�ռANͫQ'��:~lQG_�z-t�l��L�I�����p���;���q��f���LL��5{��ʩ�,d��F/���z���&/��Na]���u4<s!Z�g�\[ǆ7�X����Xx�G�޾�jU#���3t�\l�����U���٩���#��F�p������.,�g������0+)�
��娘�tI�9�)�,Qp�����g��+�Ml\�HĖ�&ڥ,�߄5�4V���$�|Ғ�j0�d�/�*�'+�g
h��`Ŵʻ�An�I��6�j=��**M�����نO�����)N�E_ (� ]<��Wњ��&��]$P��5�\C��x�0DXf��E|>�-���"9�'=�%�㴭�F+�~�b	t0[1��R�g�1Q-�I+i�ӿ�>�QpG���`�$|)��R�1���L����{�x�A���n����&��i���{d�%��Yl��{0Ri����Վu+Fh_��4z�B�����p�9P��ñܟT,J9eҲ���۴�>l�� ��j�x�:��=t�a�φ��F�b���j�$In_��'�;*?��$K��YxESj�	�jCc�j��UhL�;$�>���{����`\Qn�/�6"m�t#&���� �,
�c�&+m��p��+ ~�ג�K��S���y�ֿ�z�d����>��ӵ!���C��G�'pV!��b	\Y�?�v1�++�[���ʊ��������o7�Ax/1#�Mx���N\���mtp8����#�F��O��*�r�h��c�I�1~=�h!�pN�S���eLf٪��]�.h�(:�	�>9��I��6����WB��I�;a��k��݂Z��)X�@�\n����&Q�(	�R����دD�{��Էo|���>~�������^���v������V�G{_�Ϝ�\�#�/>��/}��Og���c�~�[�'���.��̉�/�8q����������g������c�_�|��s{��K���׾����������~�t�実���}���}��ye��k�ا��k�3/\���wn�V�����3�������z�c�\�����������{�_����}c��_������]�GnX���hݸ�������}�����׿#��Y�ԕ�<w��|����i���=5��_f~��O?�P�����������'�U���\��O:>�z�?�"9�ꚋ��v�ٽ\���������o����=5��ԙ��~����/<y�7�;��oI���>���6���7}U;��u���{J���ڞ��u|��Cz�s��W�����������W<����pY梓����'�����<~�����r������<�ŎW��ծ#���>����G���{��ڝ�~��w�䟾��@}�C�ړ_��.y�3�OM��+����}���U�}��K���x���������ٟ^���y����n������Z��ޑ�Ŵ����QB�iʹN)*-S�d�R��T�fi�V	ٷ�,���g�g/��B�y�-K�
E5�{�2Ke��=�?W?u����;��V�2[�:������yX{բ��kO��/{H�M���Ў}�[�Ƕ��bkS&/��"�/�Q�b�<j�T����l?�3����r~ٛw���i�C��Q�.�㻨��K^��������;���ݺ��g��{�=&�=aA�	�@w=ڔ�ɓ�ߪ;Ɋ�M�|<kp�}�Z�jG��O{�S���6mR����9Wv��i�Zi���{�o[N)����7w^�lc)m����䗄�y>����ף����:rht�~奲����U�L��f��3KL��Ml������i�_ty��n�9Qt�N� �$�͚k?���`����sqV�yY�G�fm��׫O������~�P���s��c�N�n]��-عe��umᵍ�A�/�gfn5~���M�ٙ�.mXx_�{<3����b��2׿�_�?:Vx�֖������3_�ι(r2��׽�����;�G?��$�^(Ϛ�*<t�N����ߵ��|x��C�ӨVe�����\n{�2���Т�˟b�'l�@���9�v��W�{y��zq����l���x��e�M�z1�����fopo�E�N/���^0�m7�΀���/D}=&o�D&z�b�v�㑻I9�;8��0wu��m-:�
6�e��ȹ�CQ�JB�/�6��E��3ɭV\_s�~�8�xШG]��z��;�(���qCKͥ��<�piM�F��c��`Ï��7+NyTh����_8QE[�G���]{���l8{��ج$���0@����]�M��k��g��f��̖�c��E��]�.�|ʖN�2Կ�����=u�(�Ƀ�H���N�g}kÃ��򞝓q�؝g-�|���b���,�]=��[5nf���u�6s6G��c�f���v���g[3�Z������Z�5��蕿����~�ѩ�&^���Hd��4�nU���we�j18sL��i���e�i��Œw�g�T������������w�*XD�X��E��3{�J��]2�~.��t��q�%�=��
���N;�%��U��������fT�9�����f�ge�D�)�Ӫk£�v��9���㾴�n���n�-��=��Bmώ���l�����~�v�Z�f����IZxҽE��^��Ash|�n��6Ќ�q{�FЊ}1�%rb��w���]�5yw]���Uˍ��7ӭDD��%���#;f�����Zꔶ�j?\?b��Y&s{7����v���k��坽�J��	�����׉�Z��`a^��g�<�Wvݦ��ەfP������[΍u�ο���;��f#7��k�ȸ'�P�ҽ��k���?o����[;�'/7.sـT�rP��./��I�Z�'/����3��<�H~q����j2���je����x���F��f^]e��Ց����V���]i���ʴm�?�9ٗ>����կc�ɻ�k�x?��ܬ��n�vyR��,���V8Q���7�����8i�e�b;�歛`l5��?��
����X>���4kF��E�������N|xi�]-�F٭�L��{"�>sQƔ�}�t�2�gxv���o�B��)�%VW>�>��Ut���gOo|l���)�m�IG�Z�^�t�U���*{N*��d�\9،}����%�Ģ��,��X�ki�:�j\����׻=	je�vB��w���ޟ�q���^>s-����c���w43� ���j<���p]	a]�#�mplƢP¶�!9E�Á���J��1���YwD���[�f�6ܻ��ߵi{V��	�8J���.���q���K���'\����zVgn��W[�}��te�9T�����A�N��c̽��UA7[�+{U�ݩ�Q��9��ǐW3����]w덁���W���=&�l�xqa�P�˿1�N��h�-�t^Z[O��_���^�8������F�x��`��\�ӗOl?��c�e�v���mEb�<�n�7ݳ��t�f����pg(����3";eX.Ȝ-Z��c����M�������3i�ߏ:�-�%���*���n�K�M;u2��i�ޒfc?��kP4?H�zP���u`��z��г�9�oԜJ�ʃ�y3���Ι|pTw�J��#��l�E9�>K�N�e�(�?2�˱'ڵ���eD���%ge����^[hVi�lY�ɧZe!�W���P�v�����e#�Y��YQ�����T�,śC����3E\b�w�������=q���%�z�N�[����g@��q��ߌc��4c�=.��I��<�oZ�7�\G��\�.n1'�7_��\�q��K�ґ�'�^�{�=�B<v�9��VW��de���G�����=&_�9IP3�y����º�N���a�.�4LN>�wm�S����WY�K����[;�v� �I����ҷ������E�k�y][tyֆcw��������CrEv���2��R�|f	��_Ǜ�_;����=���¤�����6�"vЛ_^6K��̈�����K[<J����ڒ	�.X;o5�W�5�����"�N�0�`b�q�SJ�\%���C䎺f��{t�>�w�bVp��.�����2��.�l�f`�/��ܿ'�˒�;�����ٹ�3#�jg\��h}�b�H�͝�k�zCleD����{o���*��Yj�_���̪�A.�o=�-?W���x��o��qF���P8���9���zsFk����U�~@�G0IH4L|�v�iD�ƚa-���[�����~���ΐ\0UVVub�3+k�Q��6c6,w9��`V��ֆ:;�[�9ԑ�ڻP+٤]����k��?��a�w�9�y���UCt-�zeA\/���V��=-�5rwK�A��L��p/��]۵+i����]�)g��}-;�ƬQ����f��,��5:����N�ZVM�_�/0_ �طS������[��{KwL�T^a��}��Y�c��.�����XgIp���֮<:v9���ք1�M6�?��߯yw��;kP��ֶ�_�p:����uV���9�M'�O���<�('W���ڷ��{�m�_�K�4�]�������lkS��r򏘹���O�wu�h�(�[���zI���;�c���\{޴("=��EF��*twNy	���|�a��w�m�f���[�|��뎇v����}�Q�E��e�"shs�f�j��8Y��?�O�����qm&�t��u����i�U���I}&$��<�vx�4� r���&E�w�XZTk��znV��	5%ˋr6�wT&��T�w�W<���y�Y���M��g�����ʽ:����u����'�Z���Qt����w��zB�>��)Y���cC������u��vu&W/�xtb��ɣr�������pg��ҋV��GL���9L|t���Ղ��6��Oߺ��O�iy�p/�Ι��Dj��[�7�5��;�݋v^��rx7~ž�R��㗜[�Z3ϛ�0[��c���{�O����}�]���'���"�^3]�]sd��ʺ^�:�sZ���K�vۺ��?���m}(�Mݕ�)��q��u[����-\�jx�V�[O5>��Šڮbc7�w���wF>b.%�^n2���|w��v���{U�lİ���\����{d�Z%�%mli�Z������*�k�<z���:��1�;����̙��{�d:ޙ}m�1�?K��I\S�;m��(�Ȧ�=�;Ž�_p���q-M�t�]��z㕵s�u���L��ӟa�����)�����y��u���ڵY�2#�>���R>|ӲB�����r�'rF�U�����CZ�!������fSd�C�����78�|hH�P��׶�%\(;7��y叴��i��<�S�&ʢ؝��Dl��<r���y���ee�o��.�7�4R�NTkUtc��G�����}6�c��:���k�z��~<p��9n)��7f�p6�ŘD�ӹ9˽���������蟮{Ɔt�]w<x��J�k5_z/7��՜�7�Z��A./�Gޖ�l������ݜ��.5�"�L��*g%@����O�P�gF��_�N\�n���̍��>W��|֌�NJA�ߊva��/��W��4���n5�����֞7��Q��O�/~��i�(y�z��������Q�Z�d3�x�����OeV�{��އ����m����J�贫�wÔ�6��w>�ǿ-��u�~Av��սAC�+��z��>���Ѻ�<�k���0��!�W�޻p�Y~��Á��z��[�a���+ߑVoM�هU������Ñ�^�*�r�$����^=����E��ܭ���w��G��`�<fS��ksf����W.��
V�?$��$��s�R�h�ԡ[���듫jL�gUzw���_K��ܤ�u*�}�$�����rN<��r"װ���3g%E�������ݎ�'�x�2�Jv�#rw#f/�n�9��������'���^"�i��q�o�Nu,v���2��S���M�)��$����54��x9����wFCR�����#�l����r���Rs�Wy�X��w<3�����܃<��~~�K�6�R�;V0B�D���3]�c�^��6�Lyݣ����ܝ"�s����|E'=!O7�xm��l�ѫ5Kbt�_�nAq��ݲ���^[���ձ�/iU���8��7~���ʙ[�){����e���g�=j3�^�q��w��]�%^���?����p����[���o�I����y��[�_�S����syQS�s�ؐ6��'$��-�]�gb�+��SB&t�t��]���N��[T�>zi��[-�.O��g�ZY�a�����a�[�~������R'�o]�֕�vC+����͏g��qkv�yY~��n$/p�!��_s�����#��ޕ�K�XQW跹R��+����g����.���h7�ɉ*��+'�<��TY�3�O��_�v���f�#�.-�8D����j�`
�y��N��9�o�9`���&!�
]���:�>1cb������� K-�c��n����7�a���Ŭ}��sN��2}�1}�m��|Ƙwq�y~M��t��6�]:m�K�)�����(x��o��c[\V�Nb����������a�����Z
?�X�}~c�l�i�֪Y��ʟ<�c ͇J%�9�3�������:�9+�:Q@�GG�S���_A4&�}�5$b��b[#�;�/+�ǁ|��$Vl�E �(\=�OFW̍N�b�,��˱A���QlͰ �nH��h�B�x�#($(:)��&�<��fI$B6�;���X�[�0� �b%��6�ꓕ@�b��=40s%R1q���xv���b��	<>�G��0P�� ���9�𛋠%�E'�$q6 l:Z&�J�C�'m �@Q�MH v�<�" �:��t�wF�ub�'�cbdb��A�Lp�p�!5�沥x�	e�P�����@�Ċ�0���pS�&�a�5بb�$q,ԏ�0$�RA�GËG ���P6"�?��$��P�P�s��
�B�}͗��B�{�4����1!��W03��A^��� Z��D�(&!:�@
	�Q�g�`��0_Z�?���Ó�Oe(��
1P4j( De���^޴@3܆�Gc�~t��x1�4��@/���R��}a���`?\5��$õ�� ������^ap��}��e���P =З
?���-����U�H�zтl _� /*R�Ca�gh렡T�����0i�`��=�ɀom`,LEѡ�P��Š���cЃl�;�t\.��B]���	��* B�T�@V((P�?&�4�,�3��b��D��k�w�P�(�7��;Q�4����'�?�����O�8�k��Q�m�0��W����Υ����8�i��q!�׀K�2���Ľ�9�.���N���%R�5��?���?>��=|�W�g��;;i�?����,I���	�}�Pn[���G�/��a�8��B�YI,�D�{��b�\d��	�m"e���3L��#� Ã�������'&$��θ`{2�X<;��(8(K1�
rш8b>��m`��z��y����=-MU�I���R5<��U��Ã-'4��YLr� %�),����d�S�̠����ٗ`��Q3����G�3k;3=3�����`r����Z�P%��҂xȠ@�>��r6���8�p��Hi�{B�"����Q�ד��5l��?�/��"c�V��y/4�v�:���zD����;|�r�pT���);'Z���^��'߫�`�TG(P&C|���#�?�6BB%���'���� �B�����[[�v$��(����6����U�r\A�r����\��f�h�6��*ii$65��KHŸd�'@�@�=�4x���b��2���/h�#���	0�#T����� ���
�,2�t�;�Y�J�m�#%�V��BQh$��N[��Ab�� � $a �)�U @�yԻ�z�O���$�$�ƀ�~	�o闿�g�G��-��-��
`T��SB�!a1�#�\	Wڤ6���&��e�oi
�)M@d� NS�W)ݔʅb|p�T��b�҈F�4�1hx�omL#P��	+���C�x�����R��a@ �P�__P�iE��~�7m �q<)����64�A�'�Lξ*�lE�m�����ql<݁�@V]�ۿ^�Ǡz�}O����]�����;9j�?D��"� b� a}�贡2��^�"�$��!@ª9�%Ar 4,���A��O �y��+!C^pU|P��V�a��UK��D&Be"�+��F AjAy�{:��C�p)���\D�!�`F��ǅX�����%�v5ɂ!|ȓ��lZ��C��K�(�L��JE7[�X��h2[ȇ9Jq�c����6���,	�L[�>�-�`f�DBFE1�$�BbP{DֆY�e)d�y��A���캨�>������F	a%�!Z����{����� ��>��@``VBɘt�B|���C Q�k�<��
c �!����1	�/B�Rp+��	�Z�!qB��H���C#dpĸ�tC&p��Y̑��Qf~��XR+0=�>�qD�Z�2�v��+Q�Nf���)����%�-���2��01�
���3_%7R20�S���G�@lckTr ��ۧ|qe�lTP�t���w�!��H�j�KMJ!܈l�Lm�?]�b0��vUȍUN`³���ceD~l��3.Z-�8;�% �4A�Adƣ١З�E1Ŧ����J~FA����D&� ��,6�����4�Ϝ�\<��I,	d���$0�C�@7L�i�n��t����F�JA�(0���Ó�7�>c��Dp!�DY<! >HwA�(C���$Z`Ȁɍ@��){LMց�X�|���DM�����raD���Ȥd0C��mD��s ���	��:@,bdR@AqY*��a��xXv�d�8^��Vg��P�H%�@��A�"�{T�<\4�����'��-�NB*��$2	�̕S�II��D-�8\>K/�	1z�$$S�)��Ё�,�5G��L�P�{����r4��r�2�����y����qvrB�?gG��Ϗ��Q�u~��߉�Ro�).N�������?z@�K�(@��әT74y#F:�-�I��H����c�`�L$��բ:���9�1	�$d���D�a��h�S7����MB亀�h(�����B���_8�BQ���s�5��K��,җ'��n�S�pL��h�"/���#(������ޚa���d��yH~��b�)�_�D���_�4����
0�V�Q)?p���y�,o�
:�pW�	$w6�	��`a2YE�I[�.���2� �	�*<� 7�S�<��cZ+<�@�o������/���}��c��U��.��X�2�Oà(a��?%�V���4^�Y��8C��̿Mq�D]�����*��'� E"���R����q5b��7P�b�J�� f#�{�H�"|�R}K������OZi��b�⼵�eK�`=ex�Z,�C��fRF��b,򞢽�I97����G��mV�?��/Z>		A�KE��neH�T�D��efᖮ���W�$�%Q9!	���I�Ѵb��.@p���E$g �|�E��~l�L�O��ƲM+݀,Ua5�h�ʢ�̯+��������ϯ��	|UI����
�87�t�R�'��0	 P�<̑U&�"'W.�؈q,`E���g1m�X�H�*|"��{�K#������ 6�?FH���P#q�H�8�1�4��AV%[�0�}��B��r����k	�{Q�&eD2q�0���=H��� ]�dQў�Lf�=gL�Ff��`
����7��ľ�����Xo�Y|[��/��_:?Bx>��o|�-W;�`��w���I������@�<�4~����}�}c���G�l QGI�L
��@��ib���)��9J�dR!�\l�8��u+���	�����C���hԈZq,5U5����*�Ꟗ�� ������%�����۱��;�P�4��F�+q'bV]�*.�DB�;�ԟ��qe)jFRO\��AF �^��N	��$�%MC	�1J�(�OBLꀧM��pe	,\�'P�o ׎�5Y�"U��,��� !���&!EC����T
b� �b���<$
n��z��xy!���	�	����� �8'6���	�i���rL`o�Q��(�~��"T�G�*�b�6Ⱦ�"����f��d§����0~��?Dg,��@+��Q���k0��f��N���d��Y5��a�������A������h����I�?8���ԟ�����2Q]������E ޳q,		w�#!���i�0͑'�6�Q��@�C���"*�z��(�����$H��\��9��G�=�(h4�RA�U
�s0NQAQ��� ����A^X&�P.�/��}����q�p�c��������^?�����ԏ��b�ଡ�?��G KBM%~0u�/�Q�Hqb�&�A*�pR<7U�UC������!񑄃<pZH�'��)h���+	�[�XK��͟�ȇ`��׮��\�w����;�E������oBO��mɛ"=�f����@!�S fv��l�\>�w�|����_}���g��@�z�|D
�@�8SuX?��8B�ӂB�B���y��~(������>k���գỾ�h�q�ÿJB��~r����Ǐ���n�~�?g���'����#�*7��B:����}hSxE���6�t9��� ų��8X{2 �����L_����������Pz4�؝��{��P��d�'Y��L�p܉�o4���"�?�H߰���a��d� �����m��|�|�늽�M ~��wh}R����?��������l���~*����O9���_}5����=�Fː�!��QQ�@L!� M���d��F5,��:�C<?i��`̒JY�8Y�?���)D~��߱A�'�&��ϵ�1E�7(K�Bg0������j.FAa�L��H�YT�ɚѤ�L�K�a��!C}����$P�_�� =`�tE��F��q#wk$f��>S6�qW�^,�+V8��Q�6w1Ō��!���.W�*.5�O�6S���X��C�|�HFXp#�W|m?mP�+�I	��]�������D�7��~�ji	�����jQT�� �Fa��V�1�#C�N���MU��Y��MV��d�F��9��Pu���?��P_�礉��ߐ��Gs������%�@�%� �w)M(�#ɤ����!���V�};�c@�\`[�c��_���o���4�K����O��1�_G�s��Q���)��6M��?�zb�!D[s�-���X~�������>��Ud�W���sl ���h��\��2xƿ\���"���6�����}��Bį\����`�#="� �>`;X0s�̱�Q��>��Gz��I�Z˯�TΑ�ѸX@"�ȟ�)ַl���
�gi(sl`���!����߿q����ީ!����h�����6�����G	���������wpr��/�s����~F��2�Ϡn(Zd��H� jrE�mLLc�0�d+8�	��1�E�����x�qP��a�PN��l��E bܬpP9�aΓ��!X���(�a�	 
�8݂/"~��11_�f�a��F��|����>��Dg9}%�%��\$ ~Z��X���֧C��?��PCe�_�"Y��(>�!&�m��ƀUsi.ͥ�4���\�Ksi.ͥ�4���\�Ksi.ͥ�4����?cx �  