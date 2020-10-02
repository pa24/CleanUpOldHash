#!/bin/sh -e
#########################################################################################
# этот скрипт удаляет старые хэши, по времени последнего изменения хэша                 #
# исключая из поиска тег latest.master                                                  #
# в mtime можно указать через сколько дней после последнего изменения можно удалять     #
#строки удаления rm -rf  и garbage-collect по-умолчанию закомментированы,               #
# можно запустить в пробном режиме и посмотреть какие теги будут удалены.               #
#########################################################################################

#перенаправление вывода в файл
#exec 1>log
REPOPATH=/data/registry/docker/registry/v2/repositories/
TAG_COUNT=0
DU_BEFORE=$(du -sh /data/registry)
#нахожу название репозиториев прим: aa-provider
for repo_path in $REPOPATH*; do
        repo=$(basename $repo_path)
        #echo "*******************************************************"
        #echo "repo: $repo"
        VERSIONPATH=$REPOPATH$repo/_manifests/tags/
        # нахожу название всех версий; прим: latest.claim, latest.master и т.д.
        for version_path in $VERSIONPATH/*; do
                version=$(basename $version_path)
#исключаю из обработки тег latest.master
        if [ $version != "latest.master" ]
then
                #echo "version: $version"
                TAGPATH=$REPOPATH$repo/_manifests/tags/$version/index/sha256
                REVPATH=$REPOPATH$repo/_manifests/revisions/sha256
                for hash in $(ls $TAGPATH )
                        do
                        #TAG_COUNT=$((TAG_COUNT+1))
                        #find #найти файлы старше недели, по пути  $TAGPATH/$hash
                                for file in $(find $TAGPATH/$hash -maxdepth 0 -type d -mtime +150)
do
                                        #нахожу путь к ревизиям
                                        REV=$REVPATH/$(basename $file)
                                        echo $file
                                        echo $REV
                                        #удаляю тэги и ревизии
                                        rm -rf $file;
                                        rm -rf $REV;
                                        TAG_COUNT=$((TAG_COUNT+1))
done
                done
fi

        done
done
#запуск сборщика мусора
docker exec -it  registry bin/registry garbage-collect -m /etc/docker/registry/config.yml
DU_AFTER=$(du -sh /data/registry)

echo "\n\n################################################"
echo "Удалено $TAG_COUNT тегов"
echo "размер регистри до очистки: $DU_BEFORE"
echo "после очистки:              $DU_AFTER"
echo "################################################"
