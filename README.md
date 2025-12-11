# Alpine-disk-(less)-instructions
Instructions on how to install diskless Alpine Linux with persistent data on the same disk
---
Are you on day 3 of trying to install the Alpine Linux onto the USB so it runs diskless (loads the kernel and FS (filesystem) into RAM) while having the persistent data on the **same** USB?

Do you also want the /home be persistent on the **same** USB?

Did you found out after 3 days, that the `setup-*` scripts usually format the USB along with all the partitions you painstakingly created for the 50th time? 

Are you tired of going through the `setup-alpine` for the 100th time (BTW... You can `ctrl+c` after the apk repo setup) 

This guide is for you!
---
