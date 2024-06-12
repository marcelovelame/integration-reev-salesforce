import { LightningElement, track, api} from 'lwc'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation'
import getProgress from '@salesforce/apex/SellerOnboardingValidationController.getProgress'
import completeOnboarding from '@salesforce/apex/SellerOnboardingValidationController.completeOnboarding'
import checkProducts from '@salesforce/apex/SellerOnboardingValidationController.checkProducts'
import getSellers from '@salesforce/apex/MultiSellerUtilsUnpackage.getSellers'
import basePath from '@salesforce/community/basePath';

import AlmostThere from "@salesforce/label/Atonit_Mktplace.AlmostThere"
import Create from "@salesforce/label/Atonit_Mktplace.Create"
import Complete from "@salesforce/label/Atonit_Mktplace.Complete"
import CompletedStepsHelper from "@salesforce/label/Atonit_Mktplace.CompletedStepsHelper"
import CompleteOnboarding from "@salesforce/label/Atonit_Mktplace.CompleteOnboarding"
import CompleteStepsHelper from "@salesforce/label/Atonit_Mktplace.CompleteStepsHelper"
import Edit from "@salesforce/label/Atonit_Mktplace.Edit"
import Import from "@salesforce/label/Atonit_Mktplace.Import"
import Progress from "@salesforce/label/Atonit_Mktplace.Progress"
import Skip from "@salesforce/label/Atonit_Mktplace.Skip"
import Skipped from "@salesforce/label/Atonit_Mktplace.Skipped"
import SkipStep from "@salesforce/label/Atonit_Mktplace.SkipStep"
import WellDone from "@salesforce/label/Atonit_Mktplace.WellDone"

export default class OnboardingSeller extends NavigationMixin(LightningElement) {


    @api sellers;
    @track sellerId = null;
    @track onboardingProgress;

    @track showSellerCombobox = false;

    @track showOnboarding = false;
    @track productAproved = false;
    @track showComponent = false;

    progress;
    progressWidth;
    stepsCompleted = false;
    onboardingCompleted = true;
    profileChecked = false;
    @track categoryChecked = false;
    productChecked = false;
    pricebookChecked = false;
    inventoryChecked = false;
    matchedCategoryChecked = false;
    shippingMethodChecked = false;
    landingPageChecked = false;
    isDisabled = true;
    navigationType;
    navigationAttributes;
    navigationState;

    label = {
        AlmostThere,
        Create,
        Complete,
        CompletedStepsHelper,
        CompleteOnboarding,
        CompleteStepsHelper,
        Edit,
        Import,
        Progress,
        Skip,
        Skipped,
        SkipStep,
        WellDone
    }

    connectedCallback(){
        this.getSellerOptions();
    }

    sellerComboboxOnChange(event){
        this.sellers.forEach(element => {
            if(event.target.value == element.value){
                this.sellerId = event.target.value;
                return;
            }
        });

        if(this.sellerId != null){
            this.aprovedProductVerify();
            this.checkSteps();
        } else {
            this.showOnboarding = false;
            this.productAproved = false;
        }
    }

    getSellerOptions(){
        getSellers()
        .then(result => {
            this.sellers = result;
            var sellersQuantity = Object.keys(this.sellers).length;
            if(sellersQuantity > 0){

                //Remove if need to have more than one seller per account.
                this.showSellerCombobox = false;
                this.sellerId = this.sellers[0].value;

                //Use only if need to have more than one seller per account.
                /*if(sellersQuantity == 1){
                    this.showSellerCombobox = false;
                    this.sellerId = this.sellers[0].value;
                    console.log(this.sellers);
                } else {
                    this.showSellerCombobox = true;
                }
                */

                if(this.sellerId != null){
                    this.aprovedProductVerify();
                    this.checkSteps();
                } else {
                    this.showOnboarding = false;
                    this.productAproved = false;
                }
            } else {
                this.showComponent = false;
            }
        })
        .catch(error => {
            this.fireToast("An unknown error occurred", error, "Error");
        });
    }

    aprovedProductVerify() {
        checkProducts({sellerId : this.sellerId})
        .then(result => {
            this.productAproved = result;
            this.showOnboarding = !this.productAproved;
        })
        .catch(error => {
            this.fireToast("An unknown error occurred", error, "Error");
        });
    }

    checkSteps() {
        getProgress({sellerId : this.sellerId})
        .then(result => {
            this.onboardingProgress = result;
            this.progress = result.Progress;
            this.stepsCompleted = result.Progress == 100;
            this.isDisabled = result.Progress < 100;
            this.progressWidth = "width:" + String(result.Progress) + "%";
            this.profileChecked = result.Profile;
            this.categoryChecked = result.Category;
            this.productChecked = result.Product;
            this.pricebookChecked = result.Pricebook;
            this.inventoryChecked = result.Inventory;
            this.matchedCategoryChecked = result.MatchedCategory;
            this.shippingMethodChecked = result.ShippingMethod;
            this.landingPageChecked = result.LandingPage;
        })
        .catch(error => {
            this.fireToast("An unknown error occurred", error, "Error");
        });
    }

    finishOnboardig() {
        completeOnboarding({sellerId : this.sellerId})
        .then(result => {
            eval("$A.get('e.force:refreshView').fire();");
        })
        .catch(error => {
            this.fireToast("An unknown error occurred", error, "Error");
        });
    }

    navigateToHome() {
        this.navigateTo('page', basePath);
    }

    navigateToImport() {
        this.navigateTo('page', `${basePath}/import-wizard`);
    }

    navigateToCategory() {
        this.navigateTo('new', 'Atonit_Mktplace__Category__c');
    }

    navigateToProduct() {
        this.navigateTo('new', 'Atonit_Mktplace__Product__c');
    }

    navigateToPricebook() {
        this.navigateTo('list', 'Atonit_Mktplace__PriceBook__c');
    }

    navigateToInventory() {
        this.navigateTo('list', 'Atonit_Mktplace__Inventory__c');
    }

    navigateToShippingMethod() {
        this.navigateTo('list', 'Atonit_Mktplace__Shipping_Method__c');
    }

    navigateToMatchCategories() {
        this.navigateTo('page', `${basePath}/match-category`);
    }

    navigateToLandingPage() {
        this.navigateTo('new', 'Atonit_Mktplace__Landing_Page_Content__c');
    }

    navigateToSeller() {
        this.navigateTo('edit', 'Atonit_Mktplace__Seller__c');
    }

    navigateTo(navType, navTarget) {
        switch(navType) {
            case 'new':
                this.navigationType = 'standard__objectPage';
                this.navigationAttributes = {
                    objectApiName: navTarget,
                    actionName: 'new'
                };
                break;
            case 'edit':
                this.navigationType = 'standard__recordPage';
                this.navigationAttributes = {
                    recordId: this.sellerId,
                    objectApiName: navTarget,
                    actionName: 'edit'
                };
                break;
            case 'list':
                this.navigationType = 'standard__objectPage';
                this.navigationAttributes = {
                    objectApiName: navTarget,
                    actionName: 'list'
                };
                this.navigationState = {
                    filterName: 'Recent'
                };
                break;
            case 'page':
                this.navigationType = 'standard__webPage';
                this.navigationAttributes = {
                    url: navTarget
                };
                break;
            default:
        }

        this[NavigationMixin.Navigate]({
            type: this.navigationType,
            attributes: this.navigationAttributes,
            state: this.navigationState
        });
    }

    skipStep(event) {
        var percent = 14;
        var isCompleted = false;
        if (event.target.dataset.id == 'skipProfile') {
            isCompleted = this.onboardingProgress.Profile;
            this.profileChecked = event.target.checked ?
                event.target.checked :
                this.onboardingProgress.Profile;
        } else if (event.target.dataset.id == 'skipCategory') {
            isCompleted = this.onboardingProgress.Category;
            this.categoryChecked = event.target.checked ?
                event.target.checked :
                this.onboardingProgress.Category;

        } else if (event.target.dataset.id == 'skipProduct') {
            isCompleted = this.onboardingProgress.Product;
            percent = 15;
            this.productChecked = event.target.checked ?
                event.target.checked :
                this.onboardingProgress.Product;

        } else if (event.target.dataset.id == 'skipPricebook') {
            isCompleted = this.onboardingProgress.Pricebook;
            percent = 15;
            this.pricebookChecked = event.target.checked ?
                event.target.checked :
                this.onboardingProgress.Pricebook;

        } else if (event.target.dataset.id == 'skipInventory') {
            isCompleted = this.onboardingProgress.Inventory;
            this.inventoryChecked = event.target.checked ?
                event.target.checked :
                this.onboardingProgress.Inventory;

        } else if (event.target.dataset.id == 'skipMatchedCategory') {
            isCompleted = this.onboardingProgress.MatchedCategory;
            this.matchedCategoryChecked = event.target.checked ?
                event.target.checked :
                this.onboardingProgress.MatchedCategory;

        } else if (event.target.dataset.id == 'skipShippingMethod') {
            isCompleted = this.onboardingProgress.ShippingMethod;
            this.shippingMethodChecked = event.target.checked ?
                event.target.checked :
                this.onboardingProgress.ShippingMethod;
        }

        this.progress += isCompleted?
                0 :
                event.target.checked ?
                    percent :
                    -percent;
        this.stepsCompleted = this.progress == 100;
        this.isDisabled = this.progress < 100;
        this.progressWidth = "width:" + String(this.progress) + "%";
    }

    fireToast(toastTitle, toastMessage, toastVariant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: toastTitle,
                message: toastMessage,
                variant: toastVariant,
            }),
        );
    }
}