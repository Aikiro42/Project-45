```bat
@echo off
setlocal enabledelayedexpansion

for /f "delims=" %%B in ('git for-each-ref --format="%%(refname:short) %%(upstream:short)" refs/heads/dev') do (
    for /f "tokens=1,2" %%A in ("%%B") do (
        if not "%%B"=="" (
            echo.
            echo === Processing %%A ===

            git checkout "%%A"
            if errorlevel 1 goto :error

            git rebase wip/experimental
            if errorlevel 1 (
                echo Rebase conflict on %%A
                goto :error
            )

            git push --force-with-lease
            if errorlevel 1 goto :error
        ) else (
            echo Skipping %%A ^(no upstream configured^)
        )
    )
)

git checkout wip/experimental

echo.
echo Done.
goto :eof

:error
echo.
echo Script stopped due to an error.
exit /b 1
```