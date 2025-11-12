# Not done yet.
if curl -Ik "https://127.0.0.1:8443/ords" 2>&1 | grep -w "200\|301" ; then
    exit 0;
else
    exit 1;
fi

