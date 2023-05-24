#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="392012115"
MD5="d1910354e7a359f3957bb6009e289de7"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="Next Generation Minecraft Installer (Oracle Linux)"
script="./install_server"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="."
filesizes="5305"
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
	echo Date of packaging: Wed May 24 13:48:56 UTC 2023
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
�     �=�W۸����`�-�Kr�{�~)I��	'	�����1�B����������H�+1B����Sj�͌�Ѽ$ʕ'�^��4�M�Ym6��?��Z���ԫ�z��d�Z�m4�@����4���̟j:����i)W��ްS������ݫƿ���������v1��^��#84u��LQ���3�&l�Ϡ�]ہ�vap�zڙej�r�<��}�u��a�<v:�3Osfl��c�1��;c[��93�2���i���霁:��������8��<���������C�9�Pc�b>l�P�P��N�Y�� �EUpi7�c~��:���ѭ� �j˴M�5���H��k�c��8Y���2��&�>|��K��-���z�3�R��xsZ��7���H���r��YJL_���]2��p�e��?���|�Z�{I��c�D���(#��N��i���*P��&�*���fYp�$ð_d��"ǣ�q�8��Y0u=��<�e��u����7�A�C8��;mP[C|V��Mw��2�b���B�%�zo�?�^{:�=t�C�����a��ﺽ�Óv��
^`�^'q�2��:����!;�^�c�E��;z����z�e -8nF݃��� �O��a�o#�^��r��t�:�Q{�w��`��uxH])��~@��A������^��|�����^vDWH��a�{���Q�U���#��B�	�������Z��`������~o4��-�r0����;[�t�Đ���іB��}��:
�2#����ɰ�v�u���ԘH�>.+O����>�.���T���i���&n�7����_ol�
��k���B'�e0��?���۬n��C������l1|Tj<�*\o���k�L��6@̖b�~ֿ��
��bd���n��y��[���!��Z��t*��?Qt�i����f��"Ӣ�>��9��R"�b�0oMU�1���څ��%nN�?�l
�&��R�� �.:�A����Ձ��#��'"g&�G8Rd�D���2#�>[;G�%$C) a&2��bo�-���q�Y�y����@�~4el
Ґ#6�L���#��TvQqB��nLo����ѡ���"��7C��:�v�*)��עf}��p|�%e�Ӳ~b��	Y��d�
R��iY�Ĭ����K����Ɗ��F�c�3E�8��tCˀ��e�sA�h$0�?K��!9:�_q�
1���uC�Q�}ć�a9��a�N��d�4�q^D����76y��؁�㟒�,��}|J=lZ�v�H�cJ$��`�^�ӏ� �S\�o��K��1"&�{	v�O�f6���C����P"H.�����3"[q26>�c��n�����gx?�	D5�� E$y%��d�tB���4��Y��Mkh3?��s�8Qmh�5�̄�D2���+"�^d��ם���mB�愧���\�s���ϟ%��1��D�g��� �V�������T�#��U��|���gN�" Eh� .�� ��� Ʀ�E�J?
���&��H$�E?%��M@܅/_�3���/��GwԨ�;�g�JH5��|��C�]P����.( �����|L�����*����f�
�|��g� �ed�S��]�Ɂ�
2�v��<��W�>м�,����#�!`��n�~5���w�\ǸY�.�P�H�����U�V,l�J���	���R)�����tZ��L�����Ө5��?�����)Wސ�L�p�9�%�2�a�OQZѲ@C_�M�&�>�h���\8ch!@�d.�ئ�/C����$Wc�F��O���ԐGYQ�����R��� �|���7>8�>*������r0�%���<QT��J�Wq�X.�E������#�g�-"�Ő�lY���߫T��𴬻6�`ޅfTb�K��lI0�"��+�������w��u�&7h���}m[�s(�F��S���	��_��1J��d"Fk�j�<r��kV�c@�X2��E6�K��"�#r�p��G?�)v��?�,���:�5�h�S��"�2�s�������Ȥ�KmV��*�]Ό���R\�\ �HA0V�Y��pIk��R�{�O\��L�����r>	�#�3kř��p{b��7�r��S(�"����a3���c�g�������a�i�y�+#��i��1�����^E�E�?}�9g��NC9�蓨G��&9�K����[Z�����a��+�D�%Xp�p�,��ڢJ��@����^���đ�����"�1E�2�9BV`'&7��a"M��M���{�b#�Oz�IN��v��/��2`�����{J�%���9C,W�l��q��q:DB����2�j��ZܥZ�s��A?�Z�Ǐ�_S��y���՗�w΅{� K��$�+��<Q��!O���p�W�K����!�z�(ޟm������2a�Xr��f0[��}PWJPj�ԐP:2Q�Rr���?5G�&I2�+�&�L'`-�G�u�����U��N���~���,͇���΍���S��_3�/�ap�R�����G�=��CR�G{3�kb��My��T�y��ég���%�n,�M��&�=�u좥~���S��U��~�����v Ȉ�����!9R*jT�N���{�6_Z!�R�m������Gĥw7
���m%8�k���2�I�V��.ծ��]������y�k$��O�8�0W�E�=6�͙v���[K!����#�x8%��W��#�"�R�T��'�u=2[R"�칗�TİC�%�Y���(�|PD�p#~%�l'Q��U�o�Qp(r T� d|k�����'����wr��\�˛��/xŖ�h���q����p�^��مt���.�D�0
P�`ip�B��k�x[��BT�*/�>��n�s���I�S�z|���Ҽ�]�z~|d'�� ̝�����(����2eA���!�/��܀KE�i�q�<I㜉أ���$s����[SYleh����S����hȩ�� zS��$R�t�,��7�	Nu�w�q���q3*r �1���pθ�Wn
!�4_5�R�h����]���X�U�L q��"x�������
�� �n�j�ݽn��]qn�l:���$p"�5$�$�2�E��W�p�Eۤ�B+*��β��X8�i=Q]uOo��Q
!LH�����!��dpHB��z~��<7�3�ܔZ'$Qöd���k�2�.ꥇ\L��4�ize$0�>m��S�5���3,|��'�qt�3�93�$�e�����%��
Y`W晴��fW�ܛL����+ϲpx�(Řg,i��:	~M&A*`L��w��I�M3��-�P͓_RhN m�Ɍ�?	Z��&_�c\�2h��B���k���ќ�I�"H�L3�oB�];�>�ɨ�:"�86K�RI����ϘW�����z���~��t�k���������������U��!uXU.�U�ae�����(|(�H���h����='�9i%`�ET��.��$*8j�s�+�r_�ZZNt��͝2'�.�8y���oq<��p2C�Q��<0Roq܀�������6a�"�{D[c�wr�I4�):�9�	���y�Ī�<��5�H�M�ġ�y+ˎ�)�o�B�H���u��#����)G���*F岲̄��k����X)��㞅��G);�0ٔ�c|���ÜW������z�wI����;'��;�"���2�T�'��/�����+��*[?=;��Rt\�`#����*F�sXۧ�ѿ"���$ON	��O��X�KSJ��X�����qiܙ�T��EE�*'a��2ZV��9Ր��H�R�x����dd,���E�x����e�� 6�.	W�8#�t���.��I<����X�����)��c��#�H�$�*���}ޏ��0L;rDG>s��9����&���1���A�V�^O�§j�\m|V7oW�.H�ra�[Ů�Sr>���]��Z�������m7����Ǹ���&aE�'���8"�g�Z�Ǯ�����L�׀�t�%����E_�4����a��z6��������!Q.?`��՜�����G�.��!�k3�n߽����,��������>��Gq?��5���H���5��d���B�����\/��Zh�DT.�z2��*B#�7~�Q�\���Z
ɬ�Pgo~���l� %<��t�������ǿʇ�W76�'���d�~�K?�Uqc�4��W�OqY��_|S�}n�^n��?o|�6���b���ۼ�=p�)�7��}&�<)�N%�w�Z}��?��� ��nm��߭������3����E�|�1����4�w������~0r9:t��p0��BD��阘d���+�{��_�����v~�G�^�-���Z�2}���t�G��������e���G���d��i�2t�2�f"���M;>r.�R8ߡ�i�#l�+1PqY �X :��F����]�F���M�΍{�<���݉ �����3vr�.
œpauF�g�Q���"#�\�(C���गs�n����(��d�o<���+ n��?��-�����P�7U�-�T�����ة�B9�</��ad�!chQ�?B5�DUy�̼,�E��:���;q��1��Uۮ�4��=��׊������ť��%�!�^*��:l��2)�4�(Q�}頭���@B�* �ܺ�uFߘ������gE�|����Wx>L�g���f}���?J�@�f5��
�SR+~�Pӊ�m�?��Z�{׮��ɬ/�ǵ��;�j���O�K�K.O�Ɲ�#r�r�ɷ�Q�������^l�1��C��&=�D���&�CC�����x�mpaҋ�o�lQ��Uy�F����i�z�◉[��Ǎ������ns��[+����'�ϐ/ؿ^t�ơ�����o��_�q��V�U���f��{������^t-�B��ӑ�+���8��&���6�C�n�7;�-1�g�9�����'�5�xa#}B���(#�'����wΣ��O3D^%�S'q�%��=��M��ע<���0����J�ky�O1�b��0��$5!I�ٲ1uԛ��s���ٹ��0��]l�^;�H>�[P�=�}s�b9��'�װH`.JQ�R���(E)JQ�R���(E)JQ�R���(?d�X��� �  