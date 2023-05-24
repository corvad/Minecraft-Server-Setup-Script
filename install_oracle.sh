#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2794888390"
MD5="469c29ffb6f759ab1ad7e163e2163e5d"
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
	echo Date of packaging: Wed May 24 14:12:05 UTC 2023
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
�     �=�W۸����`�-�Kr�{�~)�m�������[!^�������~g$��� �UZ�=�����H�K�\yv�eK�٤��fc3�3*Ϫ���V�ڨW��mV��۵g�x� %��x���'��.���'Zʕ��^�;h�m�>�{{���mn'�_kVq��j�[�`��{/��!�:s|�({�dꙧ� ��P۬m��vn��z�کej�r�<��}�u��a�<v2�SOsfl��c��c�;e��9S�0���I���霂:��������(��<���������C�9�P#�b>�c�@�P_�N�Y�� �EUpac7�c~��:�� �ѭ� �j˴M�5���H��k�#��8Y���2��&�>	|��K�����z�3�R��xsZ��7���H���b��YJL_���]2��p�e��?���|�Z�{A��c�D���(C��N�s�i���*P��$�*���fYp�$ð_d��"ǣ�q�8��Y0q=��,�e��m���w�~:8��~���Am�Y݀w�������~�;|���꾇�t�����Q�=@��t�:m|����w�o����pwp*#�a�C	����v�->�^u:����ΰK0_��Ђ�V��;>h�������}��t_����a�;,c��ڿ�޶�+�u���	?����w޼����~_�j#f�Wm��w��n�~����[�J_��v��m�^Q-��7���D�^�;���R��M�u�h�;b��~�pC!vb���m�X��O��xЎ�~�u��ԘH�>.+ϊ���>�Ι��D���I���f�q-�O���Fu���c�'�8v-�y������&���� eH�?��=[L��
כ�F��C�a���������o:�,�ه�����F}V�oכ�����R91�ʉ��b��0}���Y�k�ȴ���a󄡔���>�[Qs+�v�A��s�����!�@�	���( ��v���ৰ�9hu�}��ȹf��Ɂș�{,�!��#�j�G�������`	�P
H�Ɇ�(�؛gK�%o�~�{^�zv1���@��4�M&S�;�?���W��k�ƛfi{<:�г���7�f��\'�N�%E�~,jVg�	GYRV9-��!��ޘ��YJV/!e5��UI�j�،P���oK�m,9@�5JӐ�	
Ǳ��ZL�,�JG#���Y�/�������W�9��7�k�
#>��&v	]p�&�'���""G����ΛF���<D����W���S�a�������D�9av�9���>��澸�Dh#b޺`��lf��;?�H
�%��B|	�o^� �')s`�>V*6K�~�|���Cޡ@T���	RD�W�9M6M'�OPmOS��%�ܴ�6�s�>c��ՆfZ��LxI$S.�"��E��Xp�Z�̐�O�^��RP�p����� �2�����J�d��[���w��������_��I�W���98� 䔿 ��t��#P�G��\�j���2�����8s���܆?��F܂=3�BB�A�<�`)2 n��'�AA X�5��S`�l��S�����44�>Q8����<]�(� ��po�L�e��sv��n�T����fy�G� ��w����Nn��{��bl�2���p�b�GJE��&�"�bn�W�4�H@��e�J9���O�_���?�����[�Zs6��Z�����r�h��9����R"��/����-4���h���эf��̅S�62 M��m:a��2��+��Jr5�h�h����Liq�eNhA���(%8�{b��p	z|��᳢썙~�-�>�^��E5,����A�y��Y�O�n�L=���"�\i͖�qL��J�QOʺk��kF%��$+qΖ3+�?��(����oA�q�J\�or�V��׶�=�"oDj9e"�������tC&� `�f���#wB:�f��3��%��_d���Y�+2>"�	ǰ:;�3�bG/�c�I^�_SΉ<�Y�1� �(�?��ijy��L�Цe�����̈Ln�(�5����a��U�	����/(O)e����5o�/���;(�3�p>2>�F�'\Y�	�	�#&?}S*!��=�2�sI����3�_�9F�jf~/�=�k����׹2Ĺ��/����N���QD�Q���ǚs���$��>�*q�N�`�3�T�l��ر�UN����HD�[�gμ�ɡͫĸ�z�x�IN���(,�/3�#dvbrs&Ҵ��d��x �H�	6r��'��_n{�]�Jh.} {i��ٱ��X±�Q�i�1D�ru�&�q1Y'S1@$d� pnk�)Ϻ+�i��]��:�� ��0 �y���5Eʘ��M_P}�zg\����HB����e�3�IS����
av��a�8�����M?��L��C�!LKΐ��fkޙO�J	J��J�&
ZJN������$)B�tՄ��̣%��㱎}�������oո�W�?��g��C���g��F�^-��ǌ�-D\����*뻽a{x�����L���apSy2�yV;C�p�(h��v��|���	u�/G��h����D�9G6?���=��2�f�a@����U����[��t���V����7��s��?"��;��A�׶�?4>�k�$[+�]�jWe�6b~���<�5Hɧr�d�+�������~���[K!����#�x8%��W��#�"�R�T��ǎy=2[R"���TİM�%�Y���(�|PD�p-~%�l&Q��e�o�Qp(r T� d|k�����'���ͷr��\������y��h���q���p�^V�نt���B� �� Q�w0�B� /X����Z�ޖn?��ʋ�ϸ�[�\�:z�T.�("�0��a���ɦ8s�e:�/�j.�/�(o�.MY���qH�&)7�Ry�}\2O�8g"�(|E#4�\$gd��T[�f:���)�cg�r*��&���;�T-�=��{ʍ�S�z��o`܌�Hpīh5�1�9Õ��B�8͗ͣ�4Z�9�ö˵��7j�	$.�VD o�6��Y�\z �M�F-���͚�K΍�M'^�Y������V��(_�*�n>��`��XhEE^�YV�';�'�����Q8L�"�	��ߙ �1d4�H�#��B�x��|���R��$j�/�En9��Z�̽�z�"S=%�C�^	�O�w1�Dp��4�c��t���gΌ��䱌r3�>�`�\"��Ur��슝�{��ݙx��Y���#��^'���$H�	���� ɷif����y�kN
��"�q��a@0=����`�W�#_H�0pm�\:��S�V��j��MH�+�g9�Gd�f�J*i��=�������Z�nT��=��\q�K�ި͝�l�<����Ueԧ�a`U9�U���}/�k�60��H#�q�e��W���椕���Q%߻����QΨO��:�}�jXhiQ8щ�7w��|��Gs\���d���5GbD��H�A�q���#8�c��0��x{�m���ɽ'Ј��|K�L'`2���!�����4"�7���,;����
-"�?F�"�I��/��������"B�����Jdc����{�
�h����dS�r���r�sVU��+����y�$����onU���'"��XS��[\�'Z�j6�(cp�l���X�K�q�R����[r�PI/ae�F���fޒ<9%�Z>5Rc�#,M)��b٣���9�qgFR5�Iq������hYK�TC��#�JM�=�ާ����X�Z	�)>2ۗiG��x��%\���Q��
��,:'�@��fc���fu�V�����G|I"U⁥��'N9"a�v䈎|��36�e7*M���#"A����p����/�r����nޮ������ڷ(�]���|H��7����{������_�lT��������&aE�&�/�8$�g�Z�G������L�W��t�%����E_]7����a��z6��������!Q.?`��՜������G�.��!�+3�n޽����,�������f�>������_s���OD���[PSv�(+��i���0��B^����E弪'��"4�zC�W���+�����
%q��j�M'P³�L��PJ|�
�K�|�]um�~�/�OF�'���{7VOs�]U������7��g���vN����j�U��.��Z_��kOhǉwe�5�'J�w��j}�?��� ��vm��߮��I��љ�H�}Ӣ}6̘r���sv�;�}W��Ra?�:�}��~y%"l�阘d�˅�+�{���t@�a�?[s���IW���)���E�?^:�ã^��WVV2G����Y|�l��:��i�3�rv�n?>r.�R8ߡ�i�#l�+1PqY �X :��F����]�F���u�΍{�<���݉ ��^��3vr�.
œpauJ�g�R���"#N]�(�~����q7���ܡ��	uQBAɂ�xv�'�W@�&
��?t[��矡<k2��[��P����؉�B9�<O�0��1�(���T��<�rf^��"�u���ϝ�w�ߘ���m��B����"?��7swq�D�jIsH��J���LJ�'�0J�pW:h+�>�=�и��(��a��צ��cx{~��Y�%ߣg|���ߚ���Y���'���i�,��_�z��AjeͯjZ������R}����:�uW}\���5��6���������o���="'� �|Kټ��Y��p�v3�<�i�sO�
lR;4TN蜁����x�&�8�����_�wn�����<!����)�Mܪ�?n��w�+�?��y��f!����>��|.��x������������������^����j����)���;�Bx޵8=~TLGƯ(jG����KZڔy�y�l}�}��)?����w��� ㅍ�	M ��^��P��P��9��g/�y}H��NM���L jL��;�q"^��htS�3�tS�G�K���>�p�Y���R�Ԅ$g���Q�G�-�
d��b¸w��z�턷"M�\o@��F��,��J�l^�"��(E)JQ�R���(E)JQ�R���(E)JQ�R�����;kb �  