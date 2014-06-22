#!/usr/bin/env rake

task :ci => [:dump, :test]

task :dump do
    sh 'vim --version'
end

task :test do
    sh <<'...'
if ! [ -d .vim-test/ ]; then
    mkdir .vim-test/
    git clone https://github.com/Shougo/vimproc.vim.git .vim-test/vimproc.vim/
    cd .vim-test/vimproc.vim/
    make
    cd ../../
fi
...
    sh 'make INCDIR=-I/usr/include/postgresql/'
    sh 'bundle exec vim-flavor test'
end
