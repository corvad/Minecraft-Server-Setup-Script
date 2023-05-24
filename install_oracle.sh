#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1650475119"
MD5="1836b7200f233b54b4401f5fb78fe1c4"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="Next Generation Minecraft Installer (Oracle Linux)"
script="./install_server"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="."
filesizes="5313"
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
	echo Date of packaging: Wed May 24 01:45:05 UTC 2023
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--notemp\" \\
    \".\" \\
    \"install_oracle.sh\" \\
    \"Next Generation Minecraft Installer (Oracle Linux)\" \\
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
�     �=�W����Y�D�6��66��=��N���ͱMssڜYZc=\= �_��ofz�y�$�rJ$�������k�j�ك�M,�V�~�[���oU�շ���;������z}�U�g�P�02�g�o�pf��z�}��Z;��wz�Nյr�wvv����N:��-��Fk�l�����;�C�d^�4mߟ]��4��Khl6���8�-���s�ԱM;f�k���{`�0e_�i`x�6`0�̩���|0�K�� ��82l��N� �Ұf4E0�?�.��ae�0�M�@x`�f�2/2"�ob;,�є�>�-�����f{@��'����G�0
l�`l��Nl�c��쁚s��C���� ׷�	�f��Y<v�p��M��q�/Cz�9�At�� B�8B�oNk��C�ψ��dQHo.������Ix�%�m,Y�{�������q�"��=�&��]M�'c�3N�_ϏU��,U�)��c&��"{�9u��ǋlÁ����ɬb�o;0��k:����K��s z{�������OF�5���=�_C�����;؀������{t|���no����{��]�����S���@JP�ΐ�u�o���{����^wG=���?�6�����a{ �'������ �^��z��t�:�Q{�w��`��}xH]i��~@��~���������:��U1k�:숮����v�h�G�7ު�PU����zE���g������~o4���r0J���;�t�Đ׃�цF��}��:
�r#�U��d�I �A�}���ԘHT��ڳ�|e�Ȃs|�Y<�=���j6o�����Yo��ߗ��z8$�/8���Q������N}�b�����������Z��R��2"��7״Q�3"T��h1��FNJ�P6� �@̚R-x����p8�G!����E�������)��c��統���F8�L���̩�;显˔i�c�"x�<C������b��๮�x��T*8��9�p��[P�CCP� ����s�
���V'�4G�Ƕ93y�U8�I�0P��*#�!�8C�5&C9"a&2��co�bnC%�d�垗��_��';�&� 9��\9�ȍ?��?A�b�5/F��ƴ�yھf8+���~):f �3��|��cǂK?�>��3h�rߒ�C�L�:��bƯP��u�F����a9Ǽac
�f�,��P�����_�
\=Q�������>e���A�H�c�Z()s�� ��G\��3\�o��H��1"!�nlN�e�\1��e�D�4���śW/�8l�	C�<X�k�_7+��P���#�����e�$�w�
0/v�,�Q��'�\��q}�P�Ֆa;�R�
&�����!�^�^�d��ӽv�kŔ�-�~@�ޜ�5I������K����e]�{��3Mwd�?�½��[����[��o�ʔ��f`Ϣ�& )� ��\�S�V c��"�@ePzs�k)H$�â���M@܅/�����ͽp�.�1}���왃���E��c�B��C�]P����.( ����̏��U�ϴ^�s?0P%�H���8��t$
���L<F���(� ���#�|���d���,n�:A�_���W#���	�N��Ԏ�c�w���=WJ�R_�WJ�X��"ôR�o٥V�,��ss_��A�}p�������������v���<��'���6�s��8�D�!_z0�q�kZ[-E4����������%�(�,#V
M&��k{q��*��+��Js5�h攅�Li�T5m�h�Bq��j8��b��F�|��C�ᓦ�O�yƭ�㞉P��𗎁XPz��Z����g̴'���_�!��(CZ�UmE�p�V;E��q��]���sê%�Wb�ي`fM��4�(q��)n����C>�zk�;Zd������.���Ȅ2y��L_��g�{N�@�[2,��u��N�,�Ѵ�L��1|��P�?�1�f�ğ)�¹ t$,T�v���3x</�����q�9. �,>2�rPF���%�D5�RV��@��C�/���m	��d��ra\VyFGA�=�H�r1���I������,3"���eBe���Q���Ka��>���/?d���;nW���]���B��C��T!e�7p�̗��f��{�3��Km�s.�+Y��=� ��k%捨�ܕ���NqF�c9o�����3�el*?��5U�J�D<�x��a��%qCn]0�#��2��������w��6eKqdbTn�C3įJ�(�WB9�9@\%ʮֱp%%D��~�Ɯ��orJd�"4���K�C����4*w�F`c���d��;�q[��u�:Z��8"Q���|=��`���P�]��Y&��%"�,]��5�C;�y~Tg���|!�.<J7c�8"����;r퐄Jg!�C�aW�jΌ(0,��YH��RpR��I�#�U�C������� 7��\B��P@ь}��D��>n���U���2���?�P3�[��n�����������
}A\����.�����.�2���OI�[n��@�2��N�����e�?�6�0�iRB���c?mܱ�?i��ï�P���W�#I�_�`HΛ�����o�{��_�vb����\�����=,2�����k����0�Zn��uM~�A̯��Y`�V
)�*�I�����<1g��?F�&`d��C8i�!�h�Y���ʐSGV�x��ߑْ�eϿ�f���D��xn����M�%דPa�f��^�l��%�� B�BΟ��}��}�[�|��y����vQ�O�r�"Nj���2���e������-�	�4�	���� �
SP�`i@��SZ�[��B�U�� �!��n�s�k�i�U�z|T|i.��.�?9��O������l^����9DE#te��$��C_4#�ѕ����'c%�s.K ��h�é��Lܚ�b+C��da(jq���"�T��JqA�f(�I�a�>��}�-��<!�4� �|�F�r �1�D��q��,�b�i�je��2o�=�]���X�U�\�r��"�x������
�� �o�j�߽n��_qnl:ɲ��$p",$��Kޣ|�,��M���6��ЊR��Y�/.NvVO�W��[�p��ERC�2A2?b�h8�Gj?Ɓ��x�ߺ|���Q˓$(jx �E�4��Z���S��������9M���I_p�Lp��T�m�_0�"�I9c�Y0c�!a-��̧�-�7W�<�zG�������d��t&^!x����G)�<g�H��z�I�td��l~Zj��4s��R�"�� ���	��8��8��h��0��+�v��.�Z�.J.��K�Vi�����n�j�
�8���nN���Dͯ��g«���ϝf���~����k��Է���;�����/���t�{�1s$P���t�a����Q�U��̹�Ѳ�ōK=�;i%��s���]|�IUp�(��'_z�F_X�*��%��?c^�}��оgx>��x��O!`���	"E`�ހ�֌݅��۳�m*�A�Qt�'����TѤ$�3��	���!���BO �i(�7���<;TS�ߊ���2�'�p����#�j��jU[fB��b�u?5�@�l�����Oc[㣤�N<-A>M��_��0�U5�n�����-�m}$��?�翷ۥ��5���˗ਥ��Ê2���OON�����U"l�����H���Q����n�-ɓSA�R#=>�Ҕh=�=zb ��Cwf��F�"QG��I�>����iHv����4���}��9�%E�� ��G����x�$\�Tp��U����_}6��������V}�U�����+�H�$�*���}ޏ��DJf9���yV�]���&���	���~�ո^O��_�j����Y~Ѯ`�����:t(�]Ǌ�
*���]��Z�C����s뿱٬o���	��4�IX���竸�����e�1@eG����0���ux
��u��k�� ��=?p���l�4y8�������a��������D~$��p�,2�6s��݋�n��������s��\��c�����o�R�{"�?{Ń�y��ŏ�Է������X���J�vS�7U�5��MH|>C���~��v��]��$e��IW�T��3��o��N����~Կ�*߹���븁�g��ⷸ�G�+���=��zD���}�L�h�q��E����I�d���	~r��\Z�ѻ��G��v��N���R��ʹWV�����3e�w<���c~�z�˸N&�#�á�ha���ᏯD�� ��yi��؈"Ü
b�/���"����Z������ק��e ���d�t����Q�7z��y����p��%'���bW�Aَ��<}~�� 9&,NtR8���ObOX(W��(7?����3�H]��.ޥh�8+�_t�7HΟ�[s����$�� 匛�R�X.�^��	��3E��ȈS߷�p��ap�+8x�p
xyB�
(W��G�?�!p9p�(t����Z����y�A���MELU ����}ʹ�E�G#��@Sq^�j�U�y�s󲪗����b����s>���I)A���
��� �I����.��П�1<�ʟ����2�ɰ�
5ܓ�Zd��$��0ʭz\g���ޝEpVd���]~m���������K�ߓ��4mV���P=�����,=�X�F��x饾w����T𢡊k�����;e��i���s�_���8�Zp�)u�󾕳��+���=;RBF���A�����3��Z����¤�2ق��k�έ87v�'$b���>��̖hY���Y}�)*��R\~���{�������fy����^�-�N{>�-��a��_���뿱ݨ���������hO!��Z��?(�#�W_'����t�K:����� "OV���l�{qOk���F��&��mnPF OnN���Gͳ�e��>B%9S/u����=��M��ע<����0����J�E�O1�b��0��$=%��^�y���¹ETa���ZNw�.6ү���N�	��-��UE�ܢXN���5,X�R����,e)KY�R����,e)KY�R����,e)KY��͕���r| �  