# Get-ResourceGroupCreationDate.ps1

## SYNOPSIS
Retrieves the age of Resource Groups

## SYNTAX

### SubID (Default)
```
Get-ResourceGroupCreationDate.ps1 -SubscriptionID <String> [-Interactive] [-IncludeCost] [-IncludeDefault]
 [<CommonParameters>]
```

### SubPattern
```
Get-ResourceGroupCreationDate.ps1 -SubscriptionNamePattern <String> [-Interactive] [-IncludeCost]
 [-IncludeDefault] [<CommonParameters>]
```

### SubAll
```
Get-ResourceGroupCreationDate.ps1 [-SubscriptionAll] [-Interactive] [-IncludeCost] [-IncludeDefault]
 [<CommonParameters>]
```

## DESCRIPTION
The Get-ResourceGroupCreationDate.ps1 script retrieves the age of all or a subset of Resource Groups within an Azure environment

## EXAMPLES

### EXAMPLE 1
```
Get-ResourceGroupCreationDate.ps1 -SubscriptionID "12345678-1234-1234-1234-123456789123" -IncludeCost
```

### EXAMPLE 2
```
Get-ResourceGroupCreationDate.ps1 -SubscriptionNamePattern "sandbox" -Interactive
```

### EXAMPLE 3
```
Get-ResourceGroupCreationDate.ps1 -SubscriptionAll -Interactive -IncludeCost
```

### EXAMPLE 4
```
Get-ResourceGroupCreationDate.ps1 -SubscriptionID "12345678-1234-1234-1234-123456789123" -Interactive -IncludeCost -IncludeDefault
```

## PARAMETERS

### -SubscriptionID
(Optional) Provide a SubscriptionID to limit the search scope to a single Subscription.
SubscriptionID cannot be used with SubscriptionNamePattern or SubscriptionAll.

```yaml
Type: String
Parameter Sets: SubID
Aliases: SubID

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SubscriptionNamePattern
(Optional) Provide a portion of the name that will be wildcard searched. 
For example, "sandbox" finds all subscriptions that contain "sandbox".
SubscriptionNamePattern cannot be used with SubscriptionID or SubscriptionAll.

```yaml
Type: String
Parameter Sets: SubPattern
Aliases: SubPattern

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SubscriptionAll
(Optional) Switch to search all subscriptions present within the tenant.
SubscriptionAll cannot be used with SubscriptionNamePattern or SubscriptionID.

```yaml
Type: SwitchParameter
Parameter Sets: SubAll
Aliases: SubAll

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Interactive
(Optional) Enables an Interactive login instead of using the currently authenticated credentials

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeCost
(Optional) Retrieves the current Month to Day cost of each Resource Group

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeDefault
(Optional) By default, the script excludes Azure default Resource Groups. 
To include these default Resource Groups, use this switch

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
###   You can't send objects down from a pipeline to this command
## OUTPUTS

### CSV File at the Present Working Directory titled `Results-Get-ResourceGroupCreationDate.csv`
## NOTES
Version:        2.1.0  
Author:         Brandon Casey  
Creation Date:  2022.09.22  
Updated Date:   2023.03.13

## RELATED LINKS
