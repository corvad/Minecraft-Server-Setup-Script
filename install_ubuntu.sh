#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1669346837"
MD5="5b894ac7f335005d9413c4abc260a755"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="Next Generation Minecraft Installer (Ubuntu Server)"
script="./install_server"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="."
filesizes="5320"
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
	echo Date of packaging: Wed May 24 01:50:17 UTC 2023
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
�     �=�W����Y�D�6��66�r�瀓�^�9�inN��#�5V���B���3���̫���$�������k�j�ٽ�u,�V�~�[���OU��7776[[����z}kk�4�=@��� ����©a�K�]����jm����;U׺���d��[��7���������r���m2/d���O/�d��%4��g������q�؆�������=�C���_�I`x��`0�̉��5�|0��� ��qd؞흀&��a�h�`B���a蛶������e^dD���vX/�	}([�/y'3�����OpnG?� `a�&�X�3��"�g�vm�5�5�H��o�c��8Y��ر��X6�>�#|�K��5���2����xsZS�xB}J�$�Bzs>��<%v�����.oc��2���̌�U���i��Y6Qnk�?��㴈���Q(� L�Q���8p�$ð_d��!'��q�x�m80���,�U��m��ףw�A�C8���u�@o�Y_�w������Ơ����kh������5���p��?к������v�����7�
���8��8��ԡ��	�Ag��ۯ�����5�uw�#���h�a{0���px48�;����u{��K��U�W|�_��o���ԕ�>B������oގ�m��/_u������
���ow�`�}�~���e�Q5��{ۡW�_�펺��������TFI�w�agڃ��z�?Xӈ�آρ`�^G@!VCnD�
=;	@���֐��rU{V�ol�YpƂOǆyOk��������r��l�7K��1��^���#���Q/����� �߱Xp���z}�53����z��?D�����7״Q�3"T��h1��FNJ�P6� �@̚R-x����p8�'!���j�����\�QV�׎m�vl��t�h̜���c��L��=�9�7�c�0�l���1��+���=���qf@��s����'�B��?4�i ���`�<Ǫ�kxhu�HAs��plK �3��X�����ު�!b2p�S4Xc2�#f�!��:�� �6T�q�Y�y����@�~�#mlҐ#.�̕3���3|�3�,vV�b���Mo�����0��Y��������Oq��]ʏ.���OZϠ��}K�/�3�6����:���'�����r�y=���)��it�y�ȑ�מּ�M>�z� ��*�KU��|�<�ڽ���>��PR�`�A��� �g� ��~�-bDB�[��؜��\?�(b$��&� i&���7�^q؊��y��k�땟>־���!�@ j�~�E"�C蝤̋�c�^ɓM.S˸�>e(L�j˰������B[�M/rT�p�Wf�^���b�W�I�#d�O���|I�p[�p����� kY����J�d��p�f������i����2ej���(�	@
��8� 䔿 �����#P�G��\�J
���rq���p�>xs'ܹL�C�&�{f ,�D�{�q�)`!���!�6(`�xz�eP�V��v�2�gZ/ӹ����'ѱ}�P�A&>F���(� g��#�|���d���,n�:A��v����Oo����|bG̱���p��)�B���+�V�m�Z��aZ)�]v�U3���ܕ�g�i��g��U�ߍ�zc6�K�σ�2��!m�<'����J$������RD�_1�!�h�_��r�"02`�P@�d����G,�B�r��4Wc���aNX��ԐVNUӆ��.W��V�#��!�\nT��7[��>k���Z0��������ϫ8�M�p�L{l����r+�r1�]�&Q4�k�D=>����z_pfX����@��9[̬���$��>�m1�����Vo�qG�Lq��U!{�������pM&� <���+�a��toéBwh{K��c���x�	}��\4�6�)"�ҁ"�
��9Fc{ÌC��3�V8�n���*X��<bAq��Y8�>�yp��<˄�L��Q�mk�6Q'��bD?м��P��x�Il[��<��Y���U��Q�sO9ģ܄D�A0~�6?�-$ˌ��qN�PwD�w�*v�R�O������3�]���r�y[�,�P��P2w
UHY �5���"�>��fG��̂,�Rᜋm�J��e���@/�Z�y#*)w�91��QǱ��TE}��9�el*?��5U�J�D<�x��a��%qCn�3�#��2�6������w�g6eKqdbTn�CSįJ�(�WB9�9@\%ʶֱp%%D��~�ƌ��orJd�"4�����$S�	�iT�Ό�6�&����F�p�m}��A�hU��D��+��$Ã;�C��v��i�0?R����tъ��m�;��Q��6r��;�(݌��Lb�ȵC:(��X�]!�93����k�!Q�K�I��/$l�V)Ql���'[����
r	%�CE3���>����A���Fs����2��A�?�P2�[_�l�fƿ��,�5�+�ap�R�����:�0��j?%mJl9�����<�;��6l�������|W�I	e,����0�qǂ�T�9��?�>Ž��G2�f�aHΛ���O��o�{��_�vb����������=,2�������^KE�l��a��"?o!���,�}+��V��$Cki��Gl��3{�z�o#��?02v��!���OH=cV�(�2�ԑ�G^x�wd��Db��ϫ�(e�6Q��0��/"��Aa���T���F&��9�elIá(�P/����-n�(n���7�(l�q�.n�Y�|��F3��R]���Q�7V��w��x㝅78T�w�TaJ ��,HQ�RzJ��}K����U$�!d\ڭr�r�=�j�����/̥����y��'Gv�i��1�%�W �j.�@Q�]�&!I����Hnte� h���X���@�+�p�#9c������z3Y�Z��4��m��R\�)�w�F���pv_p!$O�;	8�	���Q�Hp�?�j8e�s�+7��q�/�G�i��[�m�k='�o�8�\���:ެm&bx�����& ���Z�w��5����N�,�:	I	(�҃�(_�*#nS3u�Mj,���gu��󋅓���e��V�(ep��oL�̎2��$đ�Oq�`%��*���g��$	��Iv�+ͳ��,��T/=�b���wN�++��s��܂0\�,U~[�L�Ho�}Θ̘;HX�)7�)k��%2�.�Q%7í�9�י�ם���E!��QJ0�Y0Ҭ��u��N�L�����@�b�ff�[�^$��Ќ Z#!��pG� �M�yƸpeЎ;߅T�#�E�e�9{!ي �������AYAg��͉Y�<���͞�Lx���ߍ�8��*���2���bs����fscf��Z[����8��pG��W�2Gu�lG�V�����q�XEɌ�-�mܸ�s��V~<S�����TG�rF}��A�k�Ŏ���^���S�%����(	�{���-��
�f�9� RF��iMY�]��=�߆��ıEW{L�N�=Q@M*AB9�	�0)�z2��+�����|�1�ho^˳C5E��Xh��Qa y2��Aj_�8r/7P1�V�E&�8.�_�s�T���x�=�$�5>Jj����d�W�E�x�ȇ9��	t/Q������$�������F)����'cM������%8j)������-�E�ӓ#��#r�A����0�~��;0����yK��TPj��HO���4�ZMd���g�ŝY��HTđ�r�O"���D:g��$*5M�8z�m@�G�bIj;$�/𑹡��� 1�.	W�8\:~U�@���/?��@��zs�����U�����+�H�$�*���}֏��DJ�9���yV�]���&���1���n�ո^O�z�Zo~�,�hW0�H�ra:ŮcE�ii��ˮ�y-����zcf�7֛���������&aEΦ�/�8 ���ږ�tX ��c.�k�\����)h��u���H>J��^����^�F�����Z?$
b��-��V������H��� Y<dve��ͻ�7]�;���=�F����������Z����Z���D���=�0S�5�o��*?t]��?F͕�ͦ�o(�Vk�O�6!��
� �Q&ۡ�w1e���}f&]uR	��W��_���/�'��gU�s+߽�q����Oq��-���=��zD���}�L�h�q��E����)I�d���	~r��\Z�ѻ�����s��V�������r�6�f�L��=f�1�C=�e\'������I�0���`��W"²���H���0}�SlD�aN�ڣ��������7���Cks����i���E�7Y:݃��`�?�;btp4�#F�ɢٳ�U�FG�c�)O���K�	��Υ����ʕ�8�͏}�$�L6RW濋w)�#�
��������\���ï2I�%H9�G�T(��C�t}�	�LQj!2����*���_@�
^͝^�P��~���Ot\�:
����b���Cu�d���lSS �/`�>
�\��#��O�K��8�B5��*�,ʹyY��p�U�>t~���l���6�e��7���_�t��ܞ��b�
���#�^���{l��1!�˪P�頫E���@b�2 �ܪ�uF^�������QgI�|�����F>L�w��5��o���'��h�,��_�z��!zm5�YzV�������K}������UW��m4��?���R�_zy�_���?"%Π�|J��o�,���}p}ώ��P��&=�D���%��@����V<��6�0����L������s+č]�	�شz�Oq6��Z�?�|�y��\��������� W���_y�S��2�[t��l�����?{������f�>��k�K��S���w�=��kq������_Q|��>7�_�1.萟_Tg�#�D<Y�;'���=Y�&�� @.��A�<�99�Bs5�~�!����LM���N jL�t{�q"^��x|S�s�tS���K�n�>�p�Y���R���$��zu���#�Q��sk1a܉;�H��v�[�&|�7��{V}3�b1��'[԰L`-KY�R����,e)KY�R����,e)KY�R����,e)�߮�N�Ɣ �  