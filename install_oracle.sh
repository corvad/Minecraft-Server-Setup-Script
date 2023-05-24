#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2379507590"
MD5="2239e885a5931e5cc4b367e65ddaa138"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="Next Generation Minecraft Installer (Oracle Linux)"
script="./install_server"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="."
filesizes="5385"
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
	echo Date of packaging: Wed May 24 13:22:40 UTC 2023
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
�     �=�W����Y�D�6��666����'�`sl�ܜ6'GHk��������~g���-�@J�MN���ٙ���y�R�=������n��z�����ʓz�����l7��'����v�	��<@��� ����a�+�]����j��폺U׺����޾j�����om7p��ۭ'�Y������l�y!Ӵ=vا���ϡ��؂}�ܶ`�΍S�64�������NË����1�'`N���m@��]!6�O"��l�0�/kFS����V��Cߴ��o�.�"#��&��BxM�#�B�;���h��M}�;��q��6	�؞���>;�k��9g@�!�8D
�p}˞�O�ɚ�'�N7��	�I�ː^rNn5?��9��lěӚb���3bh$Yқ����)�Cmv�x�G��gfDo���w��H3}ϲ��pG����8���E���G��@�`����Nǁ&��"{�9u��ǋlÁ����ɬb�o�0�������p�Ko��zg�������ǀ5����^A������o@��G��h���;<:�u�]��wp��뿆�خ?�I�é�@��%�^wD��ý7��y�;��mh�z�>�|5B�:�qo���3�����`����l��5�^��������;���0z�98����1b?$�`op�n�{�fo�]|����u^tEWH��A�w������.o5@(C��	���.���:�wo�􉌽A<���r8N��퍺��FĐW���F�����
�r#�U��x�M �~�s��FԘHT��ړ�|c�Ȃs|81̳xV�����j�H���Uo�������$N}�b�C�89�����,���(c���/��b
����U��%j�rh{��Ib�������mW��|#���}��j����V�\�Q֞�Nl�vb�S�t�h̜���e��L�}�1���c�0�R��ӇOu͞�S��87�R���͉�G�͠ކ���4 �Ew8�bU�3<�:оCs��p���@���=V�G���ޮ�b2p�34Xb2�"f�!��:��RjA%�d�垗��_��G;�&� 9��T9�ȍ?��?C�b�5/F��ƴ�yھf8+����e�|/2NV%E��ZԬ͓O.�qZ�nB��5!k�]A�Z1-k�������>q�u+�k�8@9_k�f =3�S#�?v,��cp�3.(=�&�g��8$�d;��+�^!��
�?A_�otx��p7,��'lL�I�̝E�������3�T�;
a�Sџ�Z?��S�a}����9�(�2�b��~��=��澸��Dh#�����\���8�H
�%��B|�^�|N�a+NR���'|��~ݬ������y�Q��c/�I^I�4�4��=A�=K�Z�lr�Z�eX@�����۹Tf�"�Zp饈�9��ug�2G�>!{s³JCU.�9�I����e]�{��3Mwd�?��ݚ�[����[��o��|��f`Ϣ�& )� ��\�S�V c��"�@ePzs�k)H$�â���M@܅/_�3���/����=Ԩ�;�g�JH5�C�B��C�]P����.( ����F}�l�����*����f�
�|��ا� Q ed���]�)��
2�q��<��W�>2��,����#�!`��n�~5�ٝ���\L�9vx.���s�T(�5}�Ԋ�m^+�0L+���]j�̂�6��ng��>�?���o�[����z���?��/��і�s�8�D�_0�q�iZG-4���h���эf�%��,c!d ��%���∅U�`W.u��jL�(1�)����j�(��>��c0��*p��Ĝ��
����GMۛ2�[.Cƽ!��GE5����A�y��YΘiOlS�?#nQ.��f��4�f�N�v���'U�wQ����^�U8g+��5�_XӴ5dⷠ��K���7�A���k���C�7"��*��UL�����Q�L�!i0Z����#F:��T�7��%��_䒹d8�/2>��Dӆ2]�B:6�|�=�C1a����0�'M����#�"ʤ\9����9BN�<	8�d�q�G)P��*��0�v�g*ą�Q�����z��,#���)癢��sۖ�?O �I!�X.��*Ϡ�hʹ�� �Qn <;�0F0~�<���ڳʜʸ����������yr�p>WB�L`O8�8rK`G,G�S���3wUX�~�><ˁ~���k��_�{27�=��sm��5�+YЖ=� [��%㚼�rH�S�;Źx�OU�G�?�/}MU�D����,��f�(Hh���Eg΢̡-*�$����M9W���������Mg��\�|rs=&���eّx AM�6�ô'�$' {�]�R�RC!{i�����uXʱ����8g�㛜M2UOq1]'�b�H��A��6�S�X%Z-61b�;y�M�B������Q����Il;�CA�����`�%�DZ�\E�h��O��wp�,_����;�!��(ޟk�$�at��LC�8��!Q`X�5���ԗ2��_H(�(�)]R����'f����TJ�����ĕ�DǾ�����4[m���������o6�ߞ��[��V�������!�uJi
��{0���8�����#!�q�2�y^BUl�(�.S�ba�-Ҍ�rVU�G>Z�'�n0i��ï��Q;�P����ٯ��0"G�}�g��=���^91j.r�Ϟ/�k�GĥwŲE��mR�m��WR�%[+�=�����ۈ���l�J!�U�8�0WZ���'��~���� ����#ux8%��R���;
�9ud��^��-)�X���j&bإ�	�9���(�|�D�p=y�l�Q��U�o��p(
 ԋ �|k��7�ۧ���ͷ
�g\�˛7��/xŖ�h�(p�U��pU/k��lC6���B� K�� ��/0T!C ��,Q�Pz-�o+�_��U$�!d\ڭs�r�8xjW���H/�k����E�U'Gv�)¸x���Z���!*�+S$)|2���ͥLD�v���,ι�=
_� ə8�5U�V�����0c8��Y�ʸ��I�	�7C�N"��f����wH��wp�S��q�E9�����pƸ�Wn
1�4_5�2�h����]���X�U�\ q��"x������
�� �o�j�߽n��_qnl:ɲ��$p,]#$��ޡ|�,������6��ЊR>�Y�..NvVO�W����p��ERC�1A2?b�h8�Gj?ā��x��|���Q˓�$j�/�EN0��Z�̽S��������!M���g,:�`&��Y���£�T�n���1�,�1_ y,��̧�-�7W��zG�������d��t&^!x��ËG)�<g�H�ƺ�I�S:	2c6�-5H�m���o)�z��Z�Bsh��Hn�i��4y���A;�6R-�|%����d+�4N��KH�k5d�=Od'f��L��{�3��W������O�]�����C��5��ԛ�����Vy��W�����̃��9�k绺԰�� }E���i$s�b��wp�R�i$LZ	��\}�{�cR5�9�ɗ^���;�
�y���Ϙ�|�F�$T��Ϸ8��)x�Ps�!A���D�4��08<�c{6�C�<�#*��΄���{��*�TR�r�0/׋�IT_yp�kJ�M�ģ�y#���b�Ed�G�A&>�&��a��rƑ{����Q��-3!�q�����B6V��������QRc'�� ��W`��U�|��@�Xq�V��.�3} ����{�Q��}$�5�ɿ��Kp�R��aE�[e��g�FXQ��*6����Ba$����0����yK��TPj��HO���4�ZOd����ŝY�1�HTđ�r�O"���D:g��$*5M�8z�m@�G�bI�8$�/񑹡L�&Ɠ�e(���KG��+���?\}N�������/��V����I�W|I"U⁥��'I9��0�:rDG!���e7:M�
��"A����q����O�j����Y~Ѯ`�����:t(�]Ǌ�
*���]��Z������ol��e��c\�i~��"�S�Wq�s	^˂#: �ʎ�1��5d.�w���4U��G�$%@x��~�r/x���n�p����]�	����D~$��p�,2�6s���[���7�B�N�Qz��v��\��C�(����v������^��g��*+t��?��U�fK�wU�5�+�{�X|��8B�c��Z���N���t�H%�O��i�h���?�����U�έ|�N�+0<kW?�-8��8�e���#B�����|�L���q��E���	�d���~P��칍�k$���n,�ۍR�{T��ʹWV�_���3e�w<������Зq�L��>�CG����Ã_��~6&"�bi��؈"Ü
b�����"���Z��m:T��Ǵ�e ���d����q�?~��i����h��%'���VW�Aَ��<q~�v?9�+�JR8���ObOX(W��h6?ƭ��3�H=��.ޥh��}f�)� 9Oγ+�+$��L�zRθ�+�%���%]�pJ9S�Z��8�}�
�������WGl�'T��rŁ�yt�����B��ݖBl��{�Λ:��m*b�����G��k^y�0��p	4�U��Q��G97/�z�N�/���]�����M��*������/q�[��rw�V*��v��{���]�˄L|2,�Bw�����������r��yc:>�w�G�Y�-zF�_��0�߭����� �����C�6���W���p�^[k��U,o��q��R߻v�g��_��k���Z�����K�K/���;��G��Ԃ�O�� ������\���ّ�*0Ҥ�r��v��P���-��"�&�8�����_�wnŁ��<!�U��)�g��@���ϲ�s\HQ�t���o���;��������Q��2�[�-��z>����7� �%�{��b��_��f�>��kl������K�@{�E��8��A	9���:�}nH��c\�!?����{��x�wNf+~�d��,l�Oh� ���e����
��q�<Y���#T�35�RgX:�1����ĉx-ʓ�mq��m��L�ĺQ���)f��+I�S�������ߌ,�[D6�ϭ�q'�b#�����D��ނ:�YU��-��J�lQ�2��,e)KY�R����,e)KY�R����,e)KY�R����,��?�]
9 �  