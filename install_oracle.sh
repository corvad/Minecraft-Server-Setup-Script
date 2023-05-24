#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3120434329"
MD5="010950ca7814fd74cdaff16af41e6259"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="Next Generation Minecraft Installer (Oracle Linux)"
script="./install_server"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="."
filesizes="5398"
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
	echo Uncompressed size: 96 KB
	echo Compression: gzip
	echo Date of packaging: Wed May 24 12:36:35 UTC 2023
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
	echo OLDUSIZE=96
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
	MS_Printf "About to extract 96 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 96; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (96 KB)" >&2
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
�     �=�W����Y�D�6��666��=��N���ͱMssڜ!����7_��ofz�	$$�rJ$�������k�j�ɽ�M,;;;�������V�I����jn6���'���6~�֓(q�ӷX85LvE��?�R�v�;�a��Z�9����W�cs;����V���6���r���m2/d���Og�}6���������-����̱M;f�k���{`�0a;��Y`x�6`0�̉���|0�LYb�42l���� �Ұf4A0�?�.��ae�0�M�@x`�f�2/2"�ol;,�gф�>�-����f{@��'����G�0
l�`l��Nl�c��쁚s��C���� ׷�1�f��i|���d,�@����%���Q���h�F�9�)v��>%�F�E!����n�;��q�a����|d��OfF􆪏}��/�4��,�(
w5m���S��qZ��z~��
h ���O��p8e�a�/��ȐP��x��6���o��*������ћ���!��u:�����o����u�dXc���B�%�{o�������x��?кGǇ�����O��W����8��8��ԡ��	�Qg���/������ew�#�/�h�q{0���p|28�;����u{/�K��U�W|�����ۇ�ԕ�>A��������^��u��/_t���Î�
��?lw�6�}�~���e�Q5��yݡW�_�G�~�����F|�@*����AwHy9�mh�Nl��@�]�#��!7"X��O�� tڇkH��DU��=)�7���,�`��S�<������wZ��b�o�6�J��K��f��?���V�Q��_z��R;�����o�7w��g��S��QF������6�qF�J��-�0��Iiʦ��YS��x��� �y/�����h�o����[������vj{�S#�h�Ì@c���sL�eʴ��b��|d{��q]1}X�T��1<�?�*�Kܜ�?8��;P�KCP� ����S�
���V'�4G/Ƕ93y�U8�I�0P��;U8F�C�q�kL�rD�L6dVU���܆J0�>�=/}=��v��mAr�%��r�����.j^�v�i�M�}9:�8pV��7�Rt���/�t�qB�nB	��5!k�]A�Z1-k����Q�͕]b݊�Z+�Nė��H��	�%�ر`�����\�x��}qH��vA�W�!E��*��.���N��nX�1�Gؘ��(h�;�f������3�T�2.
a���?W�~�ç�����;��sLQ�,ev��I��{���}q�7��2F$$��/���	����Y�#)|����+<{��9��8aH���V�}��w�O��~�;��{Q�H��zg�6���)rT���&Ƕe����nyD�e��Lj��D2���KM/rT'����e��B��g���O�s���ϟ$X˚�{��Mwd�?�½��G����G����ଅf`O��& )� �B�S�V c��"�@ePzs�k)H$�â���& �������g��]�c����3a%$ߋ���Y�9 wA��ӻ�  �����l�����*������{
@���g� Q ed�S��]�)��
2�q��<��W��,����#�%`�n�~5�����\N�9vx.����T(�5}�Ԋ�m^+�0L+���]j�̂.�k_��o�i�g��u������|�O��(���˸� �#�3�(�d�5c#��V�Bz!"�FɅ��pF����Ȁ��A��g{��^��
m�ʥ��\�	�X�9aa6SG�OUM�S�Q���ZN�N��s�T�>���{��i�f�s;l���#Tt`���c �$�!<���s|4��)3�m*�g��;�ő�yU�D�4ܭ�����j�.j���a��+�
�lE0�&�k����O�0������!7h}g���dƐ��9�:��eI�2
�IN_����N�c@�^�^.�|��"�G�4m ��.�wFL�Cc6C�x��3y��[�t��x�G!j�xj����#��g��������Q���.�Nw"�(U�	�#���2��)�Ɉ~���y�ha��ض�y����ti̪<q��)���d�G��Pb�`�$�w~�[H�����%%�e�!�?Q���s�9�]�>s�p>EB�a_x9r3W�B�S���3w
UX�~?><ˁ~���r����d0n�{rQ��gkl;V��-{<F�z�3M�8QIyU͉��\<�匧*�#�ک/��᥯�>��?W:K���>�*������Y��9�EK��_�����)Վ#����"~�鬐�˔OnN��D� 9�,;$�	�6�F~��d���`��^�p�"d/��v�K9��up��{p|��Ifh*.��t&������=Th/��6NI���F�pgu��� �HX��$���%,���CA������8K։��TN����;�{��.���z��a8�Ӏ��;r�d!J�8�C�aW8��Q`X�5���<�F�HG6Z�!+�f�O�3I����
r	%�C�I��fA��b�G���?[u��.�.�'��<l��ٚ����$(��/���0�r)M]~��G�]e�C�%��$;��@���+E��Me�,�P�#�7E*�вª���C��OE������;T��_�$� #i�{��-��A����-|O[�N�*�<�������q�kAm�������[��Ԃ�֊p���k��6b~Ů{�۷RHiU9N2h���y��s� ѐ�cd��gFF��<8�V�R�:�;
�9ud��^��-)�X���j&�١�
�9���1_�����z�*�/�Lc�ի��2j��P@�A�y
��o�O=}˛o6�8Z�7o5_��-��*�Q��X�.�H�^֊�نl$�N��NT��#��� �X� ����Wn�ҕ�*H�Cȸ�[�\�zq�ծ__������D�N�l�6���k6cA�B΂���2C���!�/Z��n�����I��9���W4BK�Gr�nMU���Id�0�XP&v�f�2]U��7E�N"�3V����Cr� �������.ʁ����s�=g��pS����y��F�� ���j����¢����۵��"oװP��@~�U���u����s�`�I�e^'��#!��y��_ea�-W�6J��V�r����tq�p��z��ꞾS 
G\�0!5�$�#�����!	q��}8X��y��g���<I����]��,�5�LB�K���)m�=���Ja�3	�=�
�q�*��p�%U���>g�?f�gH��)7��pK��rڮ�Q%7í�9�7��7��W�e���QJ0�Y0Ҭ��u�+���7�߁�$�6����B�H~-H�9�AB$7��$�hf�\��q�ʠ���G����Dsv&ي �3���
�v�� ?�����,}�I�v��&��:��n7[������=$�\s�O��j̍��N������=]fu��	յ�=]jX��B����AG#i$s�b��wq�R�iXLZ	��B}�{�cR5�9�ɗ^���;�
�y���O��|�F�$f��Ϸ8��S���C�H�7��iDw�px��l~��}n]�1�;��DU4���L'`2p�!���BO �i(�7���<;TS�ߊ����@q��#����G���*Fժ�̄���~h��
�X���Ŷ�GI��xZ�|b�1�V-�aΫj�b��[��[�5�@����o����G"��X�����|	�Z�z>�(cp�l����+��]%�F��%=#)��_������fޒ<9�Z!5��#,M)��٣'��dqgV�i�-q������h�1�Ι�d+�JM�=��g����XR��	�>27��>��x�$\�Tp�`W����_}������μ��So�J����%ɗ$R%X���q���H	ì#Gt2Ϫ��Y(��i�WH	:�W\���d-|�W���'��v��-֡CQ�:V��VP�6��v�/j�����s뿱��,���O�9�K��;��8�K�j[�ITvT���s�S^����Z7�>�&�(�{x���{���v��sh��(�-���0�jVX�H�?%�#a��d�ٵ�K��^\�u#,��������>B�������[���?{y��y���tԛs���]EW��hs�����H�j�=�OPq���e�*}�)���3��J ?���(�dO_F��g���[�᭎X`x֞.~�+~俒�}�s�
1�G��i�#����t���Fu�ض�S�����}��&�'x�ԟwͥb�m7��z��=*�O��++�6���L��=f�1�C?�e\'������y�0������"�r���H���4}�SlD�aN����s����o-����f����q���C�7Y:ݣ��`�>}�;btt2�#F�ɢ�C�U�FG�c�-���9HN��s�Υ����ʕ�8���s�$�L6RW濋w)�Gq�t\7H��[������$�� 匛�R�X.�����3ʙ��Bdę�[U8��18��Z8k�<�J�+�£���8��M������/����ɠ�/٦"�* �O�N}ʹ�E�G#��@Sq^�j�U�y�s󲪗����b����k>����ln���[���os�.���x+�SK�G�R�����cR&>�U��{�AW���݁��U@F�U댼1û�Ί,�=��/�|���������V�}������j����<���Ú�g���/����]������������U/�������3�r�_���8�Zp�)u�󾕳��+���=;RBF���A�����3�WG����¤�2ق���έ8�b�'$b���>��̖�hY���Y}�)*��R\~���ϸ\��7��2�S����]�=�~���e��_�p���l����������h�!��Z��?(�#�W_����t����l����'�q�d��gqOk���F��&��mnPF OnN��ߜGͳ�e��>B%9S/u����=��M��ע<���0����J�E�O1�b��0��$=%�.�^�z���¹ETa���ZNw�.6ү���N�	��-��UE�ܢXN���5,X�R����,e)KY�R����,e)KY�R����,e)�wY��OM �  