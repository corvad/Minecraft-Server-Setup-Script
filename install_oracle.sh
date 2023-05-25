#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1089030898"
MD5="b2015f07bda6d461edb5f10702cbfd00"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="Next Generation Minecraft Installer (Oracle Linux)"
script="./install_server"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="."
filesizes="5397"
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
	echo Date of packaging: Thu May 25 00:45:13 UTC 2023
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
�     �=�W����Y� hKn��Ʒ�C�9�I|/��47��������a����~gvW/[0��D*�D��ٙ���y�R�<{�g�F�A����v�w�<������k�ݝ��juoo�ԟ=����<�]��MgWԻ���>��Q���˶�㿷�w��׶�R�_��������`���;C82u��LQ���3��l�ϡ�]ہ�658t��vn����0�6}�t0}3�����Ӝ�[0�w�X���.h�&��{h�c:码�})X3#���ǰ��ﻺ�!<0\=��h�72-��f0f�d�9��`���PYT�f0v� <����-0�
�!*�L۔=Ps� _A����[`��9�ߌ�5	�,�o�a�0��>}��":*�>�,!��7�5���!�'��@�ȧ/�c��Rb��(���6��,�=���P��kY�%����aE����H;s���"��qDU�@0IFU�cͲ��I�a��^-E�G���qS�`�z��y2����6z��o��6tp����i�[�6��n����M�tX����A�4���?�nk��=�������Q���:�ã�V��^b�n'q�2��:��:�;n���k�e�3|������U�M8i����ӣfNN�'�A�o!�n���������a{�o��_`�ytD])�SľO��a��]������Zm�����5_�EWH��Q�s���q�u���!��B�v��M�>QM�9vz]"����u���o;��4��1�U�w��;�E��vݶ�B��̈`z?�c��j7�ր�Q��x����gޔy�4�"�Tj�o��7�����[��
��K���BǮe0��?���רm��c<C����l1|Tj<�*\o���K�M��6
@̖b�vֿ��
��bd���n�q��������{�g}�rf:�3�+��4Oa���-�t�f�i�ex��	C)1}���*���Om�A��s�����!�@����( ��v���aU8��:оCsd�Yhpr rf��p�#E�H��(�	b�3��4XB2�f�!3�*���RjA���垗|�_��G3PF� 9b��T�B`���_�b�i�	�.�1m�i��/G�z֊t�_���٪���_���yr��e��uN��M����&d}���+HYϧe]��36#�'.�nI��(�K���4�g��q�p醖37˼����H`r��Crt�*~��b��P���E�������.8�b�ٓ`�y�#�?���M#|Pb�eԒ���Z������^6��n�w�α.�	A/t�5H���)^�/ū�$B����ƽ;��`3���ŉ���]S"H������s"[q26>�k���v������a�;�j�:A�H�]:�����*�i�׳d�3��f~��y���Lk/�dj�e\D4}�P��;�9�[���	O�1� ��'9�?K��1��D�g��� ~�����'��T�?T"#���9	�� ���� ��� Ʀ�#�J�
���&��H$�E�%��M@܅/�����ͽp�.��]���왃�BY��1�+�p�}8�
�*(�F��f���j�J箧�����.pDG��*H�@Y���kxWdr�����M��G��J��w���u�@���گF�;���6�˱0������=���H}M>Ej��6��i�����.�rjA?5�_��l?d��u�����|����G���\y�yN���h�H0�!.)EiFm���>sdx�dt�>#C���-� A�!d:`�N0�M�ʦ��\�1��>f~:SC�eE��!P(��J	N������Y����{��(�c�_p��ϸ����DQKC,(=Dxx^ťc�h����#S�����u(Cکee�R9G�ó��ڨ]ySͨĴ�b%�ْ`fE��We��-��1�?���Mn�jc��ڶ��P�H��Cdx��B�c�.�o�D�v*����NH�լ2tF�֮d��l2�4�wE�G�:��Cg�~'�P��eLY �g�O�g�9т�hVp#�8�����4�<݆�@&�\j3���	G@+䃒��WG�O�'}Lp�8R6�2�Ǟ�x�9f��@�O��t��Ѣ@�5�!��yt�\
L�C3�7����	�!�<b*J�5���̳n�^���% ^�v�3�o���"�6��&	�m^R�UʱP�%��?&����>������Ϭ
��̲�K��J�fO��c��  ����#}=�J��O�����׹2�������N앒�P^)rb�c�9G�q�UBU�B�3�~qx�4Qb�iK�C81x����L$AGn\2�9��0������Rc�S��8211QV[$ '�_fQF�
��'&���f��x!�N�	6r��'��-��]�RhV} {i�����X±�Ӏ�8g(���Mr}G\L��L�\�`snk�9�,�i����]�B�9�ZGa@�7�Hr)d��7�MM_P��_ߋ�,�&R��*�Diu<�����!CI�E�C2�Mq�'1��g�~賹�;�C�!LKΐ��fkޅO��}�%%$Z�M�.(�R��#f����ID��̣%Q������<p����*��_�8����������7vw
��K��M�ܦ���*�Q�n���`�Ր�+�fTgF�Le���'��}�9n��m��+e�u���y��z�����5]�㦍T�7����"[(�Q�;Y����I��|e���"Ȗ�_<_����~'�b2�͒ԩ��W2�M�v��
����=��
��y�k$���r�d 3��x��cs�+���RH�3##�M(K*��ԣZg�V�T��*����.GfKJ$�]�����I��2��"J._�݈?@���I��|UHCF���<���������sy���)����y����a��`� ��˼�Q/����A:�{oAd��ad����G�` ��,�Q0X���C�+�_o�U����g\�mp�r�&	e+W�O�k�4��a����ʦ�C�E:{C�B�����2eE���!�/���M�Z���a��9����W4Bc�ErFnMe���U�3�O�:v�a%�b�n��MP��H����8�g܌��8�޹�����ȁ'��V��S\Y�)���|�<JM�e1�{l�Z��|�ƙ�jmEl�vmSq��5�����n�2�{ݮ������t�e��I�T��H@I`ex��2?��l����?�:���b�d��Du�=��#
�)\�0!5�$�#�����	q��C�YX���n�w(�)�<N5��-�.rh:ךe�e�K���)i�����H` }ڢs&�k���O]xg�*����3�93��3��|b��}s����wT�MO�+v�M&�Mg��gY�C�(Řg,i�:	~I&A*����@K�|�fn�[
��'��М ڊZ�8��0��h��h0+��<�lE�ڹf:_�t�vP}��+�qD�yl����a�a�oī����^}���~���D�k�����k�����/���T���!u\U��԰�߅ }E��xiDs�b���q�ޓ����p��1�
����J���ר���b��w��|�Gs\���d��5GbD��H�AD����#8�c��P��L��#����{O"�M���șN�d�L��ʃk\ӈ4�dLڛ��숚"�F(����a���'	\r���r�^m>�bT.+�Lq\�����k(�����;�yh*|���oC�M��1���y>�yUM���8|���$�:��?s�S���i�2�T�_�+._�-e5V�1�U���7��Rt�`#����*F�X;��ѿ"���$ON	��O��X�KSJ��X�����1�4��H���"�"�t���}b-c�jHvp$Q�i����t�?2K�P�"A<�Wf�2a�O���+b�\:�V���?W��y$���p�O��S��?)�?��K��,���8q�A	ô#Gt�3�(]��/�Qi�H	*�l���d-|�����g�p�vmJ�kߢ(v+:LɩH��W����������_ۮW��������&aE�X�pL��$x5N\��[Q���>��S^���E�n�}tM�Q����u=�{�k��^��sh��(����jV��D�?��#f��d�ٵ�K���@P����w��C���sI�a��j��?��B�?���HCM�,�%��Ч�!�D��O\/��Zh�X.�z2��*B#ܭ+�J�r��?��ɬ�P��~��"�لJx���t�MɃO��)�s�nl�o�Y��(�`�~x����i�q����&���&��0����!~��Dm>+:ݲC5oT;oh]{B;N�+s�	?Q��ߡ��i��l�ޣ��{���V��'��Gg."��U���0c�}�s��Y�����ʸ^*�C�á㚾�����/E�����I��X�����|����=N�gg��4�HX��������;���9>�����pmm-s���t0����'���I�=��i�3�rv��Ǟ)�����6ʕ��f�_�rHe�u���-A#�4��F'����]\Ӌ�ĐIz�A�;9r��I�0�:��S�)g�RK��k����a�O�9���/O��
J�ʳ>Ѝr�Q����G� [���&�
���
EO �?���(�3��4@#�C����I!���(g�eY-�]����܉���������n���߂�7{!�w����]]*џ����߮����M3�5<��J�O�$4��1ʭ{\g����ޝypVdɷ�_~9����w�h���=M��O�f5��
�SR+~�Pӊ�m�?��Z�{׮��ɬ�����υ�?ս��=-�/�<�+w�e�ȉ3�9'�GA6�?r�{\�]�"aF���A����y�$|�1���I/���E�����'��#OH�&��}���*����������^c��[+����'�ϐ/ؿ\t�&��������/�x��_ۭU���������xO!��Z��?*�#�W��Q^qM�%-mF�<ݼ:;�%1e5�LW��d�/l�Oh� ���e������R(�?�"���ܩ��8Ò	@��~�&N�kQ�n�sf�n��ht%ֵ<קN1�U�\I�����l٘8���¹ETa���ZNw�.6R����N�	��-��Ո��E��B��kX$0O�O�O�O�O�O�O�O�O�O��w���֔� �  