# ==============================================================================
# 自作Gitコマンド: git-branches
# 功能: 引数なし ➡️ 各リポジトリの現在のブランチ一覧を表示
#       引数あり ➡️ インタラクティブに対象を選んで一括切り替え
# ==============================================================================
git-branches() {
    local create_new_branch=false
    local target_branch=""

    # 1. 引数の解析 (-b オプションのチェック)
    if [ "$1" = "-b" ]; then
        create_new_branch=true
        target_branch=$2
    else
        target_branch=$1
    fi

    # 2. 事前チェック：対象リポジトリと現在のブランチを収集
    local -a git_dirs
    local -a current_branches
    git_dirs=()
    current_branches=()

    for dir in */; do
        dir=${dir%/}
        if [ -d "$dir/.git" ]; then
            git_dirs+=("$dir")
            local current_b=$(cd "$dir" && git branch --show-current 2>/dev/null)
            if [ -z "$current_b" ]; then
                current_b=$(cd "$dir" && git rev-parse --short HEAD 2>/dev/null)
            fi
            current_branches+=("$current_b")
        fi
    done

    if [ ${#git_dirs[@]} -eq 0 ]; then
        echo "⚠️  警告: このディレクトリ内にはGitリポジトリが見つかりませんでした。"
        return 1
    fi

    # ⭐【追加】引数（ターゲットブランチ名）が指定されていない場合の処理
    if [ -z "$target_branch" ] && [ "$create_new_branch" = false ]; then
        echo "各リポジトリの現在のブランチ一覧:"
        echo "--------------------------------------------------"
        for i in "${!git_dirs[@]}"; do
            # ご提示いただいたエイリアスの色（フォルダ名:黄色、ブランチ名:赤色）を再現
            printf "\033[33m%-30s\033[00m: \033[31m%s\033[00m\n" "${git_dirs[$i]}" "${current_branches[$i]}"
        done
        echo "--------------------------------------------------"
        return 0
    fi

    # 引数があるのに中身が空の場合（例: git-branches -b だけ叩いた時）のガード
    if [ -z "$target_branch" ]; then
        echo "❌ エラー: ブランチ名を入力してください。"
        echo "使い方: git-branches [-b] <ブランチ名>"
        return 1
    fi

    # 3. インタラクティブ選択のUIロジック
    echo "切り替えるリポジトリを選択してください（[↑/↓]:移動, [Space]:選択/解除, [Enter]:確定）"
    echo "--------------------------------------------------"

    local cursor=0
    local -a selected
    selected=()
    for i in "${!git_dirs[@]}"; do selected+=(0); done

    # キー入力を監視するループ
    while true; do
        for i in "${!git_dirs[@]}"; do
            if [ $i -eq $cursor ]; then
                printf "\033[0;36m> \033[0m"
            else
                printf "  "
            fi

            if [ ${selected[$i]} -eq 1 ]; then
                printf "[\033[0;32m✔\033[0m] "
            else
                printf "[ ] "
            fi

            if [ "$create_new_branch" = true ]; then
                printf "%-30s: %s -> \033[0;35m[新規] %s\033[0m\n" "${git_dirs[$i]}" "${current_branches[$i]}" "$target_branch"
            else
                printf "%-30s: %s -> \033[0;36m%s\033[0m\n" "${git_dirs[$i]}" "${current_branches[$i]}" "$target_branch"
            fi
        done

        IFS= read -r -s -n1 key
        if [[ $key == $'\e' ]]; then
            read -r -s -n2 key
            if [[ $key == '[A' ]]; then # 矢印上
                ((cursor--))
                [ $cursor -lt 0 ] && cursor=$((${#git_dirs[@]} - 1))
            elif [[ $key == '[B' ]]; then # 矢印下
                ((cursor++))
                [ $cursor -ge ${#git_dirs[@]} ] && cursor=0
            fi
        elif [[ $key == "" ]]; then # Enterキー
            break
        elif [[ $key == " " ]]; then # Spaceキー
            if [ ${selected[$cursor]} -eq 1 ]; then
                selected[$cursor]=0
            else
                selected[$cursor]=1
            fi
        fi

        printf "\033[%dA" "${#git_dirs[@]}"
    done

    echo "--------------------------------------------------"

    local active_count=0
    for s in "${selected[@]}"; do [ $s -eq 1 ] && ((active_count++)); done
    if [ $active_count -eq 0 ]; then
        echo "🛑 何も選択されなかったため、処理を中止しました。"
        return 0
    fi

    echo "🚀 選択されたリポジトリの切り替えを開始します..."
    echo ""

    # 4. 実行フェーズ
    for i in "${!git_dirs[@]}"; do
        if [ ${selected[$i]} -eq 0 ]; then
            continue
        fi

        local dir="${git_dirs[$i]}"
        local current_b="${current_branches[$i]}"

        (
            cd "$dir" || exit

            # 新規作成モード (-b) の場合
            if [ "$create_new_branch" = true ]; then
                if [ "$current_b" = "$target_branch" ]; then
                    printf "💤 %-35s: \033[0;34m[%s]\033[0m Already on this branch. Skipped.\n" "$dir" "$target_branch"
                    exit 0
                fi
                res=$(git switch -c "$target_branch" 2>&1 || git checkout -b "$target_branch" 2>&1)
                exit_status=$?
                clean_res=$(echo "$res" | tr '\n' ' ' | sed 's/  */ /g')

                if [ $exit_status -eq 0 ]; then
                    printf "✨ %-35s: \033[0;35m[%s]\033[0m %s\n" "$dir" "$target_branch" "$clean_res"
                else
                    printf "❌ %-35s: \033[0;31m[%s]\033[0m %s\n" "$dir" "$target_branch" "$clean_res"
                fi
                exit 0
            fi

            # 通常モード (checkout) の場合
            if { [ "$target_branch" = "main" ] || [ "$target_branch" = "master" ]; } && \
               { [ "$current_b" = "main" ] || [ "$current_b" = "master" ]; }; then
                printf "💤 %-35s: \033[0;34m[%s]\033[0m Main/Master branch protected. Skipped.\n" "$dir" "$current_b"
                exit 0
            fi

            local actual_branch="$target_branch"

            if [ "$target_branch" = "main" ] && ! git show-ref --verify --quiet refs/heads/main && ! git show-ref --verify --quiet refs/remotes/origin/main; then
                if git show-ref --verify --quiet refs/heads/master || git show-ref --verify --quiet refs/remotes/origin/master; then
                    actual_branch="master"
                fi
            elif [ "$target_branch" = "master" ] && ! git show-ref --verify --quiet refs/heads/master && ! git show-ref --verify --quiet refs/remotes/origin/master; then
                if git show-ref --verify --quiet refs/heads/main || git show-ref --verify --quiet refs/remotes/origin/main; then
                    actual_branch="main"
                fi
            fi

            if [ "$current_b" = "$actual_branch" ]; then
                printf "💤 %-35s: \033[0;34m[%s]\033[0m Already on branch. Skipped.\n" "$dir" "$actual_branch"
                exit 0
            fi

            res=$(git switch "$actual_branch" 2>&1 || git checkout "$actual_branch" 2>&1)
            exit_status=$?
            clean_res=$(echo "$res" | tr '\n' ' ' | sed 's/  */ /g')

            if [ $exit_status -eq 0 ]; then
                printf "✅ %-35s: \033[0;32m[%s]\033[0m %s\n" "$dir" "$actual_branch" "$clean_res"
            else
                printf "❌ %-35s: \033[0;31m[%s]\033[0m %s\n" "$dir" "$actual_branch" "$clean_res"
            fi
        )
    done

    echo ""
    echo "✨ すべての処理が完了しました。"
}