#!/bin/bash
# Autor: Gonzalo Mejias Moreno
# Calcula la memoria libre


total="$(free -m | grep 'Mem:' | awk '{print $2}')"
free="$(free -m | grep 'buffers/cache' | awk '{print $NF}')"
diff="$((${total}-${free}))"
result="$(echo "scale=2; ${diff}/${total}" | bc | cut -d '.' -f 2- | tr -d '\n'; echo %)"

echo "Total: ${total}MB"
echo "Free: ${free}MB"
echo "Porcentaje de uso: ${result}"

exit 0
