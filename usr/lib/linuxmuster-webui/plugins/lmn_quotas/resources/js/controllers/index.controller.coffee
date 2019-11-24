angular.module('lm.quotas').config ($routeProvider) ->
    $routeProvider.when '/view/lm/quotas',
        controller: 'LMQuotasController'
        templateUrl: '/lmn_quotas:resources/partial/index.html'
    $routeProvider.when '/view/lm/quotas-disabled',
        templateUrl: '/lmn_quotas:resources/partial/disabled.html'


angular.module('lm.quotas').controller 'LMQuotasApplyModalController', ($scope, $http, $uibModalInstance, $window, gettext, notify) ->
    $scope.logVisible = true
    $scope.isWorking = true

    $http.get('/api/lm/quotas/apply').then () ->
        $scope.isWorking = false
        notify.success gettext('Update complete')
    .catch (resp) ->
        notify.error gettext('Update failed'), resp.data.message
        $scope.isWorking = false
        $scope.logVisible = true

    $scope.close = () ->
        $uibModalInstance.close()
        $window.location.reload()


angular.module('lm.quotas').controller 'LMQuotasController', ($scope, $http, $uibModal, $location, $q, gettext, lmEncodingMap, notify, pageTitle, lmFileBackups) ->
    pageTitle.set(gettext('Quotas'))

    ## TODO
    # Quota for class
    # Quota for project

    $scope.toChange = {
        'teacher': {},
        'student': {},
        'schooladministrator': {}
    }

    $scope._ =
        addNewSpecial: null

    $scope.searchText = gettext('Search user by login, firstname or lastname (min. 3 chars)')

    # Need an array to keep the order ...
    $scope.quota_types = [
        {'type' : 'quota_default_global', 'name' : gettext('Quota Default Global in MiB')},
        {'type' : 'quota_default_school', 'name' : gettext('Quota Default School in MiB')},
        {'type' : 'cloudquota_percentage', 'name' : gettext('Cloudquota Percentage')},
        {'type' : 'mailquota_default', 'name' : gettext('Mailquota Default in MiB')},
    ]

    $http.get('/api/lm/quotas').then (resp) ->
        $scope.non_default = resp.data[0]
        $scope.settings = resp.data[1]

    $scope.$watch '_.addNewSpecial', () ->
        if $scope._.addNewSpecial
            user = $scope._.addNewSpecial

            $scope.non_default[user.role][user.login] = {
                'QUOTA' : angular.copy($scope.settings['role.'+user.role]),
                'displayName' : user.displayName
                }
            $scope._.addNewSpecial = null

    $scope.isDefaultQuota = (role, quota, value) ->
        return $scope.settings[role][quota] != value

    $scope.findUsers = (q, role='') ->
        return $http.post("/api/lm/ldap-search", {role:role, login:q}).then (resp) ->
            return resp.data

    $scope.userToChange = (role, login, quota) ->
        delete $scope.toChange[role][login+"_"+quota]
        ## Default value for a quota in sophomorix
        value = '---'
        if $scope.non_default[role][login]['QUOTA'][quota] != $scope.settings['role.'+role][quota]
            value = $scope.non_default[role][login]['QUOTA'][quota]
        $scope.toChange[role][login+"_"+quota] = {
            'login': login,
            'quota': quota,
            'value': value
        }

    $scope.remove = (role, login) ->
        ## Reset all 3 quotas to default
        $scope.non_default[role][login]['QUOTA'] = angular.copy($scope.settings['role.'+role])
        $scope.userToChange(role, login, 'quota_default_global')
        $scope.userToChange(role, login, 'quota_default_school')
        $scope.userToChange(role, login, 'mailquota_default')
        delete $scope.non_default[role][login]

    $scope.saveApply = () ->
        $http.post('/api/lm/quotas', {toChange : $scope.toChange}).then () ->
            $uibModal.open(
                templateUrl: '/lmn_quotas:resources/partial/apply.modal.html'
                controller: 'LMQuotasApplyModalController'
                backdrop: 'static'
            )

    $scope.backups = () ->
        lmFileBackups.show('/etc/linuxmuster/sophomorix/user/quota.txt')

## Archives
    #$http.get('/api/lm/class-quotas').then (resp) ->
        #$scope.classes = resp.data
        #$scope.originalClasses = angular.copy($scope.classes)

    #$http.get('/api/lm/project-quotas').then (resp) ->
        #$scope.projects = resp.data
        #$scope.originalProjects = angular.copy($scope.projects)

    #$scope.specialQuotas = [
        #{login: 'www-data', name: gettext('Webspace')}
        #{login: 'administrator', name: gettext('Main admin')}
        #{login: 'pgmadmin', name: gettext('Program admin')}
        #{login: 'wwwadmin', name: gettext('Web admin')}
    #]

    #$scope.defaultQuotas = [
        #{login: 'standard-workstations', name: gettext('Workstation default')}
        #{login: 'standard-schueler', name: gettext('Student default')}
        #{login: 'standard-lehrer', name: gettext('Teacher default')}
    #]

    #$http.post('/api/lm/get-all-users').then (resp) ->
        #$scope.all_users = resp.data

    #$scope.isSpecialQuota = (login) ->
        #return login in (x.login for x in $scope.specialQuotas)

    #$scope.isDefaultQuota = (login) ->
        #return login in (x.login for x in $scope.defaultQuotas)

    #$scope.save = () ->

        #teachers = angular.copy($scope.teachers)
        #for teacher in teachers
            #if not teacher.quota.home and not teacher.quota.var
                #teacher.quota = ''
            #else
                #teacher.quota = "#{teacher.quota.home or $scope.standardQuota.home}+#{teacher.quota.var or $scope.standardQuota.var}"
            #teacher.mailquota = "#{teacher.mailquota or ''}"

        #classesToChange = []
        #for cls, index in $scope.classes
            #if not angular.equals(cls, $scope.originalClasses[index])
                #cls.quota.home ?= $scope.standardQuota.home
                #cls.quota.var ?= $scope.standardQuota.var
                #classesToChange.push cls

        #projectsToChange = []
        #for project, index in $scope.projects
            #if not angular.equals(project, $scope.originalProjects[index])
                #project.quota.home ?= $scope.standardQuota.home
                #project.quota.var ?= $scope.standardQuota.var
                #projectsToChange.push project

        #qs = []
        ##qs.push $http.post("/api/lm/users/teachers?encoding=#{$scope.teachersEncoding}", teachers)
        ##qs.push $http.post('/api/lm/quotas', $scope.quotas)
        #qs.push $http.post('/api/lm/schoolsettings', $scope.settings)

        #if classesToChange.length > 0
            #qs.push $http.post("/api/lm/class-quotas", classesToChange).then () ->

        #if projectsToChange.length > 0
            #qs.push $http.post("/api/lm/project-quotas", projectsToChange).then () ->

        #return $q.all(qs).then () ->
            #$scope.originalClasses = angular.copy($scope.classes)
            #$scope.originalProjects = angular.copy($scope.projects)
            #notify.success gettext('Saved')
