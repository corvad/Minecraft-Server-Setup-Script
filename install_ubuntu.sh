#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1516248927"
MD5="e0c63e9ed9972223af1f3cf23f7f9d94"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="Next Generation Minecraft Installer (Ubuntu Server)"
script="./install_server"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="."
filesizes="5324"
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
	echo Date of packaging: Wed May 24 13:51:20 UTC 2023
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
�     �=�W�H��YE#�	��2����|v�ͳ�d�f����txt�x��ߪ>t�92��H����������.�f��?+��n��,�*�z�V��v+�g���^��4�=B��P�	yfx&��A����'Z��Q���v4�|����ۻj���{��Wk�:���WFv���r��#ˠn@�Л�}�|�m���Vk���,�z�L?�-]QN��XA`y.�2�>=��s_wCjO)��Ę��9�!�GtwN����w�k��D'�������8��}
�Dϰt�GLψ�z���-�d;�P�E��Ĥ��X.�:YE.�p�E!�i���0v��vd"�ڶK���FP�x��3�1����itf[�d���>�Bx�K������$��� �f�&رo�)24,
����s��X�2�|������X�P#�7��سm�I3<״��`_QFP��y3�h���z!��Q��&�*���n��
�A��^=E�����qCK����Y�dj����_�޵���A��n��&jk��y��ퟎ|1h�F�I�5i�ޓ�t{����ɠ3��@��u;��;<:mw{o�+h���$��T��>��ng���;�÷��z�=���(����|��9iF��ӣր��N��t���n�� z�wz#z�w��+<�����v��N��G�'��7oG�m��݁��:�Y��Q�wD���;��:n��V}�2P�3�y�������=u�=$���q������i�Cd��A�xGAvB�>�zYM2#����$�N�`�1�(?֔gE������3�<Ӎ�hZ~����h�D���Q)���2�SH�x�I����`r,��^��,���(#���/��|
����Ux�4
��[.5|}>[�}��Y��+��?�}|���[��!k���������Q>���Læ��Pc���ϡҴ��O!yC]�sC)]>}���*֘l�?��NJ%�K̜�0�T�����\��Eg0�6�Sr��`u�}��L���d@��d=j�F
�	����	`P��`�Dh(�(�DCjj*��;Bj��?N?�=/y���OV��-Np�A��4#�}"?�B�&�����ƚfi�zt�o�Ik����{n���K�h��P�/פ[~-*6��"q	����ҳ�ڼ	E �&ms���+��̧nS��	��T�� 'zH.��6�܋�m]0A��(0�?���`��'*�b���H�/�n�7*� ��n����bcpv�ؤ�4�����%�?��fM%> �C�?%����xJ=lZ�v�X]`��	s�k?r��\�).�7Ņ_B���ֻ$NdL�CT��Ha��@]�/���W/�8h��\�����vK?(!��c���x���D��{�l�n䜁ڞ�z3K6�iM}�}AaG�Mݲ��Lx�$c��%��"Cu���Ho#�7'<��P�B�ß�|�"0���9�G*��tY�y98(����S�~WU"��r`��4��D;0C 3@L�[@�-��=�~�@��M n& �H
 󛀸_�3��{��]�cx.h��س a-$��ѧ��!�.(@�hz8�uP �#?��C��?�z��=_3�#�S>���u�ȁ�2�����@Y�@��;,�t�u�.�3�=�p��_� oz'��;m �+��܅�K0g&�
��&��Z���+y�a& ���KEK/����7�����q���֨6�?*����8���+o�[&�	8�]�	�l�aOQZrY��/�& ��� -o���h.�Ӑ�K!��\�\�Xn�@#-�����\�	%�1�A:SCX���)�# :��}�DN����5\"}��#�ᓢN�q�,�e�����GF5l����F`y���YL�a�-C�?�Cfa.��f5e��`�\>ԣ3������n�c�K��l�3�,�ʊ�	쏝��v��A��n�Js���v���-G##`�x�?#˧�.�D �,֢y�MQ'�m�t�lb�<t9h.�v���?a"w&"���Z0�,��5�:�5���s�C	F�9�,�S��mpD�ȥ>�X���|3C���Q�k��) Ƈ*>��.	cm_b�R�p���5o/��x� �3��p62���{�2n�O~��TSgJ4��%��s���B�1�73�{u��`ܰ�4�Ε̍Ȳ�x���xluc���"���И��9���H�/�DV¨�y�$gx�6�xc���>��,?L7`š�@�/)̜eu�A[V�a��6����N���&E���Lg�,ǎOnF�Ky�z�L+�(�6�F^��d��b�퐱���ˀ��^2tv�+ �p,c�3Qb{c�H��\L�ٜ
Y6�ۺβ�4�դc=��_�Rg���~�(��Ǐ�_����tf��KϿ`�=g��x�\�(��%Mu�0d�ǅ٥�҇�`ȧ>2���XAЅ�5|L�0��!������� �%5(��-����wE���IPL�r�%���K�	��c���o��Sۭ�r��V��<��g��c�����h֪���5��\� �)�)���^��',{H�q�7���wؔǾHe^��@9���y���0���j\�4�������Oy����m��k���'#n�[��#e����t�}ޣ���ڎ@��m+�x��]� .��Q�h<0m+�����Z3��
a���MQ��_���P���R�'�J�h~��9ӎU��)���q��$�ԃrbF�D*ENX}�W��%˞w��"��/�Φ,7�GIŃ�C�[�R���$J�]��q�"B%BƷ��}5�}�[ݼ��<�\ݼ��|�+�F#�����������^6��#��߽�	Yl$DvyC2$㥄�a�Px-�ok�_
��U���!�L�m1�2=	x*W���H��k��p�e���Gv�)��y����Z��!��+S)lR��I��TDw͓4Ι�=_�L2�۰5i|+�̠A�2��,�@L�8�Л�|G����gavϙ1L`��s�����QҁDNX���<g��`S�(���y��F�<���v��Kb�V�3�������ڦ���k�+?o �	ܪev��]So͹�����2���S�A%�i�=��ʂ���Tl�(���ecy�0��z�������.\����	��F���
q��c���K��Ϥ���8!	���-�Lk����p1�SҀ9��� ��e#�r�1�J�0�1Ɵ��CΘ�̘{H�(7��c+��5����Q7}�);�7��7��W�U���Q�1�X0¬1t��L�T��-�@+�|�fa�[	��'���Ђ �A!��`�� ���~��aአs�s����� sv.�
 �s�r�	�v�4'������,�H'M~��?c^}m�/~W��a����~��O4�G���i�����5���+��U�A}LV�ف*4��{.@_�!#�4�w1X���q��$6'����J�w�=&Q�A�\P�<�u�����e8э�7oJݸZ?�q򀫻��X2���d
��JbD�����qC���C8�k��0��x{�m���ɼ'��Ir��t&"�j2��+.1MCj�ɘ��7�d�!��fĵ���(1HE��1l_N9r�6@1�4e�	�����T}CJhc����wY
%9v�ii�){�Z�5���0U5����wz�wE��#�����׬U���'"��XS��[X�G.e5V1�u�vzv�%y\�B#R�%9\ȍ��d� F��v3k���H� ���ᖦ�@[��QcakFҸS3�1�DF�*'n��2ZT��9��`)Q�i����t�?2K�P�FA<�G�"�hO����c�.�*�@�[�U�$I��m,��Ҭ�j��J����K��,��8q�A(�aƑ�:
�k�.�<ݨ8�K���������h-|�hZ��E1��]A���e�:�1�]�]��|���7�������*Յ�_�mT
��)��$��[��I�������i��g���1��5��wɾa)h�f]�|a=l�<�a^�j���`�\?(
"�c,t���l}��_b�����X���̥�wo(t�� �;���=�F�������ǰ�A�/�ͽ��"�?}݂�zX�KȬЧ�!>G��9�Y���1�˪���
����k�ie�˯���BJ���O�:@�O)	O?Q�C)������̇9P���'�I��,���~x�����y��������´���� ~���m�(��B�q�o���s����{2���;]���g,�=��l�ޣ��{�%��Z��OJ��g.����E�b�1�e���,bw�����~d�18x�0��hp��+ak�cb�!/W��,�!_��b���-���&^	[�����E ���x�t�O��Q�7����1;>����d��i�tC��m�Ey��ɻv|���p����"�� Wb��� v��<��F���]�F���mύ��,��0MOމ ��^!g��ȝţp� u��g�c���#�=��H��~�ഗs�n����:�PP��/,��#�+ n��?��-���D[4U�K�)��s ���3�r�y^��ȦC��d�_��T����rf^jj�N�/�N<��o4����z}���߃�7{���������T�_���(�K��<��_&e��n�%lx ��И�Hd^ħ�[������1�;?��ɒ��3��
�ǉ��{K����?I���f=��
�SR�[A�Tӊ�m�?��Z�{׮��ɬ�������R���(~�������S�q�_��?��s�-qd������+��s�Pz%a�3O�
T;tPN𜁸���x��&=?����_�unF>��=!!�j���'nU�ǿo��w�k�?{�e�o���E�?g��?C�`�z�����W���x��ï�j�ZY��Uw��S��%w�=��kq�������_�׎�y�Uᗴ�9���} m��)>c������� ��qM��Ln{3BYr{|@	�<h��4C��!2����3,� ��iwo�D�����8g��H��Wb]�s}���\%�+IR�t�-[SW�Y0��*h��[�	cN��F���މ4�s�u̳*�[X�)>ټ�EsQ�R���(E)JQ�R���(E)JQ�R���(E�[����ݛ �  