# Common Wizardable mini-wizard routes

get :edit, action: :new
post :edit, action: :create

get 'check-answers', action: :new
post 'check-answers', action: :create

get :confirmation, action: :new
