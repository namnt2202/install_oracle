###################################
#
# $Header: coraenv.sh 17-may-2007.08:31:33 jboyce Exp $ coraenv
#
# Copyright (c) 1987, 2007, Oracle. All rights reserved.
#
# This routine is used to condition a C shell user's environment
# for access to an ORACLE database.  It should be installed in
# the system local bin directory.
#
# The user will be prompted for the database SID, unless the variable
# ORAENV_ASK is set to NO, in which case the current value of ORACLE_SID
# is used.
# An asterisk '*' can be used to refer to the NULL SID.
#
# 'dbhome' is called to locate ORACLE_HOME for the SID.  If
# ORACLE_HOME cannot be located, the user will be prompted for it also.
# The following environment variables are set:
#
#       ORACLE_SID      Oracle system identifier
#       ORACLE_HOME     Top level directory of the Oracle system hierarchy
#       PATH            Old ORACLE_HOME/bin removed, new one added
#       ORACLE_BASE     Top level directory for storing data files and
#                       diagnostic information.
#
# usage: source /usr/local/coraenv
#
#####################################

#
# Set minimum environment variables
#

if ($?ORACLE_SID == 0) then

    set ORASID=$LOGNAME
else
    set ORASID=$ORACLE_SID
endif
if ("$ORASID" == '' ) set ORASID='*'

if ($?ORAENV_ASK == 0 ) then
        set ORAENV_ASK=YES              #ORAENV_ASK suppresses prompt when set
endif

if ($ORAENV_ASK != NO ) then
    echo -n "ORACLE_SID = [$ORASID] ? "
    set READ=($<)

    if ("$READ" != '') set ORASID="$READ"
endif
if ("$ORASID" == '*') set ORASID=""
setenv ORACLE_SID "$ORASID"

if ($?ORACLE_HOME == 0) then
    set OLDHOME=$PATH           #This is just a dummy value so a null OLDHOME
else                            #can't match anything in the switch below
    set OLDHOME=$ORACLE_HOME
endif

set ORAHOME=`dbhome "$ORASID"`
if ($status == 0) then
    setenv ORACLE_HOME $ORAHOME
else
    echo -n "ORACLE_HOME = [$ORAHOME] ? "
    set NEWHOME=$<

    if ($NEWHOME == "") then
        setenv ORACLE_HOME $ORAHOME
    else
        setenv ORACLE_HOME $NEWHOME
    endif
endif

#
# Reset LD_LIBRARY_PATH
#
if ($?LD_LIBRARY_PATH == 0) then
    setenv LD_LIBRARY_PATH $ORACLE_HOME/lib
else
    switch ($LD_LIBRARY_PATH)
    case *$OLDHOME/lib* :
        setenv LD_LIBRARY_PATH \
            `echo $LD_LIBRARY_PATH | sed "s;$OLDHOME/lib;$ORACLE_HOME/lib;g"`
        breaksw
    case *$ORACLE_HOME/lib* :
        breaksw
    case "" :
        setenv LD_LIBRARY_PATH $ORACLE_HOME/lib
        breaksw
    default :
        setenv LD_LIBRARY_PATH $ORACLE_HOME/lib:${LD_LIBRARY_PATH}
        breaksw
    endsw
endif

#
# Adjust path accordingly
#

switch ($PATH)
case *$OLDHOME/bin* :
    setenv PATH `echo $PATH | sed "s;$OLDHOME/bin;$ORACLE_HOME/bin;g"`
    breaksw
case *$ORACLE_HOME/bin* :
    breaksw
case *[:] :
    setenv PATH ${PATH}$ORACLE_HOME/bin:
    breaksw
case "" :
    setenv PATH $ORACLE_HOME/bin
    breaksw
default :
    setenv PATH ${PATH}:$ORACLE_HOME/bin
    breaksw
endsw

unset ORASID ORAHOME OLDHOME NEWHOME READ

# Set the value of ORACLE_BASE in the environment.  Use the orabase
# executable from the corresponding ORACLE_HOME, since the ORACLE_BASE
# of different ORACLE_HOMEs can be different.

# The return value of orabase will be determined based on the following :
#
#  1.  Value of ORACLE_BASE in the environment.
#  2.  Get the value of ORACLE_BASE from oraclehomeproperties.xml as
#      set in the ORACLE_HOME inventory.

set ORABASE_EXEC=$ORACLE_HOME/bin/orabase

if($?ORACLE_BASE != 0) then
   echo "The Oracle base for ORACLE_HOME=$ORACLE_HOME is $ORACLE_BASE"
else
   if (-e $ORABASE_EXEC) then
      if (-x $ORABASE_EXEC) then
         set BASEVAL=`$ORABASE_EXEC`
         setenv ORACLE_BASE $BASEVAL
         echo "The Oracle base for ORACLE_HOME=$ORACLE_HOME is $ORACLE_BASE"
      else
         echo "The $ORACLE_HOME/bin/orabase binary does not have execute privilege"
         echo "for the current user, $USER.  Rerun the script after changing"
         echo "the permission of the mentioned executable."
      endif
   else
      setenv ORACLE_BASE $ORACLE_HOME
      echo "The Oracle base for ORACLE_HOME=$ORACLE_HOME is $ORACLE_BASE"
   endif
endif

#
# Install local modifications here
#

