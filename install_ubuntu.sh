#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="337677017"
MD5="84f3c920656c6bb00a852b48a529cc42"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="Next Generation Minecraft Installer (Ubuntu Server)"
script="./install_server"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="."
filesizes="5409"
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
	echo Date of packaging: Thu May 25 00:47:33 UTC 2023
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
�     �=�W����Y�D�6��26ؾ����N�{��ئ�9mN���XEW��/����]�la�R��iwggfwg絋V}r��6>�V�~�Z�����yR����i�[�Z��v��l՞@��<Q�>��3Y0�vE����U{����9�}��ټj����t�w�u��z�������7�C�`n�����}�l�3�9Է�;��/,<�B?�-]Q���XA`y.XL��N�p��n��-����7c��glBtw3���;u˵�3�����NL�M�K�gX�=<����9�����X6�Y8e��d�9��d��X.PY\�V8��|��e�-�\ÎL�!.�-ǒ=Ps΀@A�Q��[�x�5�ߌ�5�Nm+�n�i��(ď}��":���m!X�7�5Ŏ�!�g��P�(�/�S��Sb�$�]��6��,�=�����P��g��%�fx�iE�����H?�.�E��녈�@�`���,
��m�)��~��z�����㆖n���y�dj���.�/�o��.�Fp<���t;��G��n������dXc�����%��o�?�~g��=vG#����a���z��ÓN��
^`�� 'q�2�:��z�;�^�k�E�7~�������`m8nǽ�����O�ǃQ�� �~��r��t�������7���/0z�><����	b?$��`p�v�{�z���.~|�E��/��+$���;ڂN�����[�P�j;x�K���6��{�>�q0菇���T�I�7�Qw��ވ�r88�R���b��`�~W@!VCnD�
����	@�tۇkD��ĸ��<)�ol�������qͪ������b��m����%�f#�S�6��P�N���o��ۥ��Ϙv��=[L� ��
ϟ�F��#�e��OB������o��l��ه��kۍ�΂���l���!����S˭���T1l��
3��o�mx�M�>��+�2_J�@������bM�)��_�P��\�����q�fPkA�OA�
��;�O�*�.Zhߡ9r��hpr rf�58"{$\kip��������l�LM��|GJ-�������ϋ��P�`����!G2�*:���g����Fhݘ6�4Oۗ�È|{M:xӯ��sC�t]Rd믅�hr�&%��KQ��H��K�Z13O�'h�&�ܚ��E�6� n���I���3ɚ�p��!\z�m�܋��ι�tu�ܟ%��\�큊��{���7�����»xx�6
��6�`'�M���9�x�d����x��ء���ZQ�_S�~�Ƿ���������"<e!"�G.��W�<�+��x��Dh�^{��D�搒�<��kJ���<{��9��8aH���Z�m��ӻ�'xw?�	Duǋ�0C$�.ݳtku#���,�y�ək���s��<Qm�=���_�dj��CL4}�Q�ȃ;/��;���	�.w���G9�?I��9��D�'��� ~��U��`���L��Ub#��5�� �� �  ���@[.��*�*�җ�@�HA"���@�7q�|��o>w���sQ����k!!���>X�9 wA�G���  ���%A�>��N����t��:k�)��Gtb���D�u��NQ�FwE� �:������6_��P��<�ۣ�@藀���A���fw�߻�p9�Bf[�]x�Cq.b�"V_�O�Z���+E�a� �߲KE�.�G��v۝��L��������X������� ���+oD�!�	8�]��	F|��(�%�(�x£��P�Gc���,o���d����� h2�,ˍBh�Ʈ�*�՘���Sd35�-�)�(���Ba0�S*p�wĜ��
�����E9�2��$C�]��'�j�:bA�!��*.]�C�'�1ÚXF�����C��NՔi΂�j�Q�N5�sP��/t���^�U8g+��U�_PU�d⼠������7�Ak�-�k��C�7"���*&�bF��(]&ؒ�4�T*%�Ǜ�����&�֮d��2�t;�D�G�?�#w�~��P��Z0�,����'�3���4+8�1De��Yd��Z�nCC �F.�9v�F��#��AI�sȵ#ܧ�Ǔ>f8cL)Q���,L<D�3Ht(�'V\z�9�hQ�˞s�B�:s=_�q.&֥Λ�Q�9����}1�!���`������;v	�W����&����H����I�q�.)�*�X��@�eυ	x{�������0{�/Ǉ2�l���:�
2�93�`y���Y�s��H�ȭ�ս'Sꆽg!u��q�G�m&B��&d��x�d,�W�}��Tw�Pz�Fr�P��G��á_^*M�Dx:���L��8IБۄ��gβ:̡-��8w�Ԙ�ޅEyZ���8�-�3�/�(cdvr��.�f�3�P��p'x��yAړAҖ��.x!4�!��4d��S�,�X�i�i\0����&��c.��t.H.Up8�u���jD��&zds�pm����o.��I��=�\
Y"��gV ��₯��A�|�tWpy�tz#����ᐡ��"��%�.p�g>1���XA���;�C�!LKΐ��M���y@��}��%$Z�,�.(�R����+f����KE��̧%Q��F�_�y�6�_��&��[�2��A�?'�6�c��Z�F������B� �)�)��rԾ�{����k5�銽ՙ�/S���z;n��F�[2�|S��
E9�� �N��`&���߶ߡ��}ܴ�
2�f�����\dKu*�fK�w�;iW�^�j��c�ϗ��Cĥ�	�X��Ga��u��f����B�����_�83���RZU��`�5Z�yb�v%��z�&`d���ei���zT��Ȏ�ʐSCV������lI�Ĳ�]j�Xp�4,�?�!���E����T؟�����B2���P@�A�yMW���O�����6�8�W7�-j���\�����V��}x��^6��iB6��ق� +�� q��#�(�2�G�`�.���~)�-W��ȇ�qi�ɹʭ�4��\=>q��ʼ�]&Rrd+��"�_��b���7��Е)+�>|ј�o&ׂv��,ι\����3�qk��V�V��� c�Y�����I��7C�N"U�fO��s3*��TGxg>8�7@c"�"Z�{Nqe�1N�U�(3�V�D>c��Z/��[5΅��k+b��k�	�ܮa�����&p�����vM�5�F���,˼N'��EJ��-��ʂ�;X|�Qj,��b��,O�';�'����Q8��"�	��ߘ Y1d4�I�#��#��J<�wS�C�˨�I�5�Hv�C�5��,sK�^���LOi��Of
�ӗ��0\�,�}��;�T�.���1�,�1�!-0��,&��7���zG���u�����d��t&^!xV%:�R�y΂�f�y���tdR���� )�i���jE�kI
-��$��c0�BZ�ف�(�\�2h�C q0�V����UH�k5`��=W��'f��l:����y����~���,��~��O5����i�o�������}Uf���W��}UjX��B���ic
��4�w1Z�{�q��iTSZ	Xx��1�
����I���ר�E�bӄo�ܤX?�Iڅ����x2�G�x���
	"E`�� "�!݅��˵�m(��D�B�mO��ɽ'1И���S�L'`2�A-B&Q}��5�iĚo:&.��[yv�M3ZDv�1����.9|_�8r�6P1�4e�	!�����P��2^�;�,��R<v�mi�ɘZ�5��0U5���÷�-"���?�,��v�R�?�Oƚ�����Kp⥬�Ê2������zP�"VBl���å�H���S��_���[�'��R+�Fj"|��)%�f"{��@ؼ�,��L���"�#�t���}-�iHvp,Q�i����l�?rK�P�&A<�W�2ak�O���+b�1\:�V����?W��y ���t�O��S���J���#��D��K�E?N�r��0����5+�l�nT��R�'D�
G�z=Yk�Vk|RL�hW�/H�ra�ŮaE�)i��j����|��_�����ۍ�N����O��x`w�q>���6M8�|�o�=�r��̡�Ny��׺i��5�G	�ó��;�^o4�Ρ�C� 2=~�F��Ya�#}��ȏ�]��Cf�f.ݾ{A���X�	<n�!/5�G��-$}<��_�/��l����$�?{���yY�K�Y��OC����^���0ԍ�(\V�d@UU�F��P��V�V�q�d�'��SK?�v�|� %<�������O���ʇ�W7��o�Q�ά|�T�{����뮹����&���&�ܴ����!~��Hm>)ݲC5oT�hh<gF;N�+s�	?Q��+]��X�r�?��� ���d�7��T�|�"}_�h_3fܷ<���F�o(���e�~0�8:�p0��BD�:٘�d�/+�W���/��������,����n�Y��G��e ���d���q�?~��i����h1KN�-ޓ�/z�B˶�b"���M'9�/�=S8ߥ�i�+l�+	Pq���!>��F����[�F�i�g:����.xvpM/�C&�=)g���]�'��ꜮO9��9J-EF�y��Ag�/����-�_�P'Tl��g����m������A"�~�=h�&�
?g�
EO �?��z(�s͋4@#��@���1�i!�ʋ(�楦�����r�Ľ��F������m���[���/d�[�sXW*���t��{���}���|�M�B�������̫���r��}c:|>�w�G�5Y�-z�W_��0��T������ǩ�iڬ��_�z��Aju3��jV������RK}����9�����6�s���V�Y���ǥ����|�ο�9q���[�(�����B~����Za�!��H��{"�U��ڡ�r"�o<ƃ6�0����L������s3���v�		�L�ާ�y�V�x����?�pm���Z���K�_�����3�K�/]�Ih�pǨ����ŋ=���w�E�_}���=F�_z�c� /�Ǒ��J���E�dRT\�~I[��!O����;�DLY�;'�?�{�XL6�'4A�\n{�2Byr{r@)����ׇ�I���M�a���tO�{'�(O&��97L�Ez2��z��S���*̮$IMI�q�l�\�fd��"��A~n�&�;q����Nx'҄���q�jL�¢XM���5,�˧|ʧ|ʧ|ʧ|ʧ|ʧ|ʧ|ʧ|ʧ|ʧ|��o����u �  